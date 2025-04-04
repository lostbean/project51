defmodule Area51Web.InvestigationChannel do
  use LiveState.Channel, web_module: Area51Web

  alias Area51Core.GameState
  alias Area51LLM.Agent

  @channel_name "investigation"

  # IMPORTANT: Only implement callbacks from the LiveState behaviour. Adding
  # callbacks from the Phoenix.Channel will likely mess up with the implementation
  # on the LivState.Channel after the macro is expanded

  def channel_name, do: @channel_name <> ":*"

  @impl true
  def init(@channel_name <> ":" <> session_id_str, _payload, socket) do
    session_id = parse_session_id!(session_id_str)

    # Check if we need to generate a new mystery or use an existing one
    game_session =
      case Area51Data.GameSession.get_game_session(session_id) do
        nil ->
          # Generate a new mystery
          case Agent.generate_mystery() do
            {:ok, mystery_data} ->
              # Create session with the mystery data
              IO.inspect(mystery_data, label: "fooooo")
              Area51Data.GameSession.fetch_or_create_new_game_session(session_id, mystery_data)

            {:error, reason} ->
              :logger.error("Error generating mystery: #{reason}")
              nil
          end

        existing_session ->
          existing_session
      end

    # Get any existing clues for this game session
    clues = Area51Data.Clue.get_clues_for_session(session_id)

    state = %GameState{
      game_session: %Area51Core.GameSession{
        narrative: game_session.narrative,
        id: game_session.id,
        title: game_session.title,
        description: game_session.description
      },
      user_id: socket.assigns.user_id,
      username: socket.assigns.username,
      clues: clues |> Enum.map(&(&1.content))
    }

    {:ok, state, socket}
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
  def handle_event("new_input", %{"input" => input}, state) do
    username = state.username
    game_session = state.game_session

    # Log player contribution
    Area51Data.PlayerContribution.add_player_contribution(game_session.id, username, input)

    # Trigger LLM to generate next narrative and extract clues
    case Agent.generate_narrative(game_session.narrative, input, username) do
      {:ok, new_narrative, clues} ->
        # Update narrative in game session
        updated_narrative =
          game_session.narrative <> "\n\n#{username}: #{input}\n#{new_narrative}"

        new_game_session = %{game_session | narrative: updated_narrative}

        # Update game session in database
        Area51Data.GameSession.update_narrative(game_session.id, updated_narrative)

        # Store any clues that were found
        new_clues = []

        if length(clues) > 0 do
          new_clues =
            Enum.map(clues, fn clue ->
              Area51Data.Clue.add_clue(game_session.id, clue["content"])
            end)
        end

        # Update clues in game state
        updated_clues = state.clues ++ new_clues

        {:noreply, %{state | game_session: new_game_session, clues: updated_clues}}

      {:error, reason} ->
        :logger.error("LLM Error: #{reason}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_event(unmatched_event, unmatched_event_payload, _) do
    :logger.warning(
      "received an unmatched event: '#{unmatched_event}' with payload '#{inspect(unmatched_event_payload)}'"
    )
  end
end
