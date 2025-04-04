defmodule Area51Web.SessionListChannel do
  use LiveState.Channel, web_module: Area51Web

  alias Area51LLM.Agent

  @channel_name "session_list"

  def channel_name, do: @channel_name

  @impl true
  def init(@channel_name, _payload, socket) do
    # Fetch the list of available sessions
    sessions = Area51Data.GameSession.list_sessions_for_ui()

    state = %{
      sessions: sessions,
      user_id: socket.assigns.user_id,
      username: socket.assigns.username,
      error: nil
    }

    {:ok, state, socket}
  end

  @impl true
  def handle_event("create_session", %{"topic" => topic}, state) do
    # Generate a new mystery based on the provided topic
    case Agent.generate_mystery_with_topic(topic) do
      {:ok, mystery_data} ->
        # Create a new game session with the mystery data
        Area51Data.GameSession.create_game_session(mystery_data)

        # Fetch updated session list
        updated_sessions = Area51Data.GameSession.list_sessions_for_ui()

        # Return the new session ID in the response so the client can join it
        {:noreply, %{state | sessions: updated_sessions}}

      {:error, reason} ->
        :logger.error("Error generating mystery: #{reason}")
        {:noreply, %{state | error: "Failed to create new session"}}
    end
  end

  @impl true
  def handle_event("refresh_sessions", _payload, state) do
    # Fetch updated session list
    updated_sessions = Area51Data.GameSession.list_sessions_for_ui()

    {:noreply, %{state | sessions: updated_sessions}}
  end

  @impl true
  def handle_event(unmatched_event, unmatched_event_payload, _) do
    :logger.warning(
      "received an unmatched event: '#{unmatched_event}' with payload '#{inspect(unmatched_event_payload)}'"
    )
  end
end
