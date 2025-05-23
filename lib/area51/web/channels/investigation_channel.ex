defmodule Area51.Web.InvestigationChannel do
  use LiveState.Channel, web_module: Area51.Web

  alias Area51.Web.Auth.Guardian
  alias Area51LLM.Agent
  alias Area51.Web.ChannelInit

  require OpenTelemetry.Tracer

  @channel_name "investigation"

  # IMPORTANT: Only implement callbacks from the LiveState behaviour. Adding
  # callbacks from the Phoenix.Channel will likely mess up with the implementation
  # on the LivState.Channel after the macro is expanded

  def channel_name, do: @channel_name <> ":*"

  @impl true
  def init(@channel_name <> ":" <> session_id_str, %{"token" => token}, socket) do
    session_id = parse_session_id!(session_id_str)

    socket = ChannelInit.assign_channel_id(socket)
    Logger.metadata(request_id: socket.assigns.channel_id)

    OpenTelemetry.Tracer.with_span "live-state.init.#{@channel_name}", %{
      attributes: [
        {:channel_id, socket.assigns.channel_id},
        {:session_id, session_id}
      ]
    } do
      Guardian.verify_and_get_user_info(token)
      |> case do
        {:ok, user} ->
          :logger.info("User '#{user.username}' has authenticated into channel #{__MODULE__}")

          # Check if we need to generate a new mystery or use an existing one
          game_session =
            case Area51.Data.GameSession.get_game_session(session_id) do
              nil ->
                # Generate a new mystery
                case Agent.generate_mystery() do
                  {:ok, mystery_data} ->
                    # Create session with the mystery data
                    Area51.Data.GameSession.fetch_or_create_new_game_session(
                      session_id,
                      mystery_data
                    )

                  {:error, reason} ->
                    :logger.error("Error generating mystery: #{reason}")
                    nil
                end

              existing_session ->
                existing_session
            end

          # Get any existing clues for this game session
          clues = Area51.Data.Clue.get_clues_for_session(session_id)

          state = %{
            username: user.username,
            game_session: Area51.Data.GameSession.data_to_core(game_session),
            clues: clues |> Enum.map(&Area51.Data.Clue.data_to_core/1)
          }

          {:ok, state, assign(socket, username: user.username)}

        {:error, reason} ->
          :logger.warning("WebSocket auth failed: #{inspect(reason)}")
          :error
      end
    end
  end

  defp parse_session_id!(str) do
    case Integer.parse(str) do
      {session_id, ""} ->
        session_id

      _ ->
        :logger.error("received an invalid session id: " <> str)
        raise("received an invalid session id: " <> str)
    end
  end

  @impl true
  def handle_event("new_input" = event, %{"input" => input}, state) do
    OpenTelemetry.Tracer.with_span "live-state.#{@channel_name}.event.#{event}", %{
      attributes: [
        {:event, event}
      ]
    } do
      username = state.username
      game_session = state.game_session

      # Log player contribution
      Area51.Data.PlayerContribution.add_player_contribution(game_session.id, username, input)

      # Trigger LLM to generate next narrative and extract clues
      case Agent.generate_narrative(game_session.narrative, input, username) do
        {:ok, new_narrative, clues} ->
          # Update narrative in game session
          updated_narrative =
            game_session.narrative <> "\n\n#{username}: #{input}\n#{new_narrative}"

          new_game_session = %{game_session | narrative: updated_narrative}

          # Update game session in database
          Area51.Data.GameSession.update_narrative(game_session.id, updated_narrative)

          # Store any clues that were found
          db_clues =
            if length(clues) > 0 do
              Enum.map(clues, fn clue ->
                Area51.Data.Clue.add_clue(game_session.id, clue["content"])
                |> Area51.Data.Clue.data_to_core()
              end)
            else
              []
            end

          # Update clues in game state
          updated_clues = state.clues ++ db_clues

          {:noreply, %{state | game_session: new_game_session, clues: updated_clues}}

        {:error, reason} ->
          :logger.error("LLM Error: #{reason}")
          {:noreply, state}
      end
    end
  end

  @impl true
  def handle_event(unmatched_event, unmatched_event_payload, _) do
    :logger.warning(
      "received an unmatched event: '#{unmatched_event}' with payload '#{inspect(unmatched_event_payload)}'"
    )
  end
end
