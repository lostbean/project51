defmodule Area51.Web.InvestigationChannel do
  # Type issue with livestate
  @dialyzer {:nowarn_function, [build_new_state_message: 2, build_update_message: 3, join: 3]}

  @moduledoc """
  A `LiveState.Channel` that manages the state and interactions for an
  individual game investigation session.

  It handles user authentication for a specific session, initializes the game
  state (including mystery generation and clue retrieval), and processes
  player inputs to advance the narrative and uncover new clues via an LLM agent.
  """
  use LiveState.Channel, web_module: Area51.Web

  alias Area51.Data.Clue
  alias Area51.Data.GameSession
  alias Area51.Data.PlayerContribution
  alias Area51.LLM.Agent
  alias Area51.Web.Auth.Guardian
  alias Area51.Web.Channels.ChannelInit

  require OpenTelemetry.Tracer

  @channel_name "investigation"

  # IMPORTANT: Only implement callbacks from the LiveState behaviour. Adding
  # callbacks from the Phoenix.Channel will likely mess up with the implementation
  # on the LivState.Channel after the macro is expanded

  def channel_name, do: @channel_name <> ":*"

  @impl true
  def init(@channel_name <> ":" <> session_id_str, %{"token" => token}, socket) do
    session_id = parse_session_id!(session_id_str)
    initial_state = ChannelInit.init(socket)

    OpenTelemetry.Tracer.with_span "live-state.init.#{@channel_name}", %{
      attributes: [
        {:session_id, session_id}
      ]
    } do
      Guardian.verify_and_get_user_info(token)
      |> case do
        {:ok, user} ->
          :logger.info("User '#{user.username}' has authenticated into channel #{__MODULE__}")

          # Check if we need to generate a new mystery or use an existing one
          game_session =
            fetch_or_initialize_game_session(session_id, initial_state.otel_span_ctx)

          # Get any existing clues for this game session
          clues = Clue.get_clues_for_session(session_id)

          state =
            initial_state
            |> Map.put(:username, user.username)
            |> Map.put(:game_session, GameSession.data_to_core(game_session))
            |> Map.put(:clues, Enum.map(clues, &Clue.data_to_core/1))
            |> Map.delete(:otel_span_ctx)

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

  defp fetch_or_initialize_game_session(session_id, otel_span_ctx) do
    case GameSession.get_game_session(session_id) do
      nil ->
        # Generate a new mystery
        case Agent.generate_mystery(otel_span_ctx: otel_span_ctx) do
          {:ok, mystery_data} ->
            # Create session with the mystery data
            GameSession.fetch_or_create_new_game_session(
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
  end

  defp process_and_store_clues(clues, game_session_id) do
    if length(clues) > 0 do
      Enum.map(clues, fn clue_data ->
        Clue.add_clue(game_session_id, clue_data.content)
        |> Clue.data_to_core()
      end)
    else
      []
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
      PlayerContribution.add_player_contribution(game_session.id, username, input)

      # Trigger LLM to generate next narrative and extract clues
      case Agent.generate_narrative(game_session.narrative, input, username) do
        {:ok, new_narrative, clues} ->
          # Update narrative in game session
          updated_narrative =
            game_session.narrative <> "\n\n#{username}: #{input}\n#{new_narrative}"

          new_game_session = %{game_session | narrative: updated_narrative}

          # Update game session in database
          GameSession.update_narrative(game_session.id, updated_narrative)

          # Store any clues that were found
          db_clues = process_and_store_clues(clues, game_session.id)

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
