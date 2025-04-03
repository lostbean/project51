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

    game_session =
      Area51Data.GameSession.fetch_or_create_new_game_session(
        session_id,
        "The investigation begins..."
      )

    state = %GameState{
      game_session: %Area51Core.GameSession{
        narrative: game_session.narrative,
        id: game_session.id
      },
      user_id: socket.assigns.user_id,
      username: socket.assigns.username
    }

    {:ok, state, socket}
  end

  defp parse_session_id!(str) do
    case Integer.parse(str) do
      {session_id, ""} ->
        session_id

      _ ->
        :logger.error("recieved an invalid sesssion id: " <> str)
        raise("recieved an invalid sesssion id: " <> str)
    end
  end

  @impl true
  def handle_event("new_input", %{"input" => input}, state) do
    username = state.username
    game_session = state.game_session

    # Log player contribution
    Area51Data.PlayerContribution.add_player_contribution(game_session.id, username, input)

    # Trigger LLM to generate next narrative
    prompt =
      "Continue the Area 51 investigation based on the current narrative: #{game_session.narrative} and the latest input: #{input}"

    new_game_session =
      case Agent.generate_narrative(prompt) do
        {:ok, new_narrative} ->
          %{
            game_session
            | narrative: game_session.narrative <> "\n\n#{username}: #{input}\n#{new_narrative}"
          }

        {:error, reason} ->
          :logger.error("LLM Error: #{reason}")
          game_session
      end

    {:noreply, %{state | game_session: new_game_session}}
  end

  @impl true
  def handle_event(unmatched_event, unmatched_event_payload, _) do
    :logger.warning("recieved an unmatched event: '#{unmatched_event}' with payload '#{inspect(unmatched_event_payload)}'")
  end

end
