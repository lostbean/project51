defmodule Area51.Web.SessionListChannel do
  # Type issue with livestate
  @dialyzer {:nowarn_function, [build_new_state_message: 2, build_update_message: 3, join: 3]}

  @moduledoc """
  A `LiveState.Channel` responsible for managing and broadcasting the list of
  available game sessions.

  It handles user authentication, fetches the current list of game sessions,
  and processes events to create new game sessions or refresh the existing list.
  """
  use LiveState.Channel, web_module: Area51.Web

  alias Area51.Data.GameSession
  alias Area51.LLM.Agent
  alias Area51.Web.Auth.Guardian
  alias Area51.Web.Channels.ChannelInit

  require OpenTelemetry.Tracer

  @channel_name "session_list"

  def channel_name, do: @channel_name

  @impl true
  def init(@channel_name, %{"token" => token}, socket) do
    initial_state = ChannelInit.init(socket)

    OpenTelemetry.Tracer.with_span "live-state.init.#{@channel_name}", %{} do
      # Authenticate using JWT token
      Guardian.verify_and_get_user_info(token)
      |> case do
        {:ok, user} ->
          :logger.info("Authenticated WebSocket connection for user: #{user.username}")

          # Subscribe to session creation events for real-time updates
          Phoenix.PubSub.subscribe(Area51.Data.PubSub, "session_list")

          # Fetch the list of available sessions
          sessions = GameSession.list_sessions_for_ui()

          state =
            initial_state
            |> Map.put(:sessions, sessions)
            |> Map.put(:username, user.username)
            |> Map.put(:error, nil)
            |> Map.delete(:otel_span_ctx)

          {:ok, state, assign(socket, username: user.username)}

        {:error, reason} ->
          :logger.warning("WebSocket auth failed: #{inspect(reason)}")
          :error
      end
    end
  end

  @impl true
  def handle_event("refresh_sessions", _payload, state) do
    updated_sessions = GameSession.list_sessions_for_ui()
    {:noreply, %{state | sessions: updated_sessions}}
  end

  def handle_event("create_session", %{"topic" => topic}, state) do
    case Agent.generate_mystery_with_topic(topic) do
      {:ok, mystery_data} ->
        GameSession.create_game_session(mystery_data)
        updated_sessions = GameSession.list_sessions_for_ui()
        {:noreply, %{state | sessions: updated_sessions, error: nil}}

      {:error, _reason} ->
        {:noreply, %{state | error: "Failed to create new session"}}
    end
  end

  def handle_event(unmatched_event, unmatched_event_payload, state) do
    :logger.warning(
      "received an unmatched event: '#{unmatched_event}' with payload '#{inspect(unmatched_event_payload)}'"
    )

    {:noreply, state}
  end

  @impl true
  def handle_message({:session_created, %{session: _session}}, state) do
    # Refresh the session list when a new session is created
    updated_sessions = GameSession.list_sessions_for_ui()
    {:noreply, %{state | sessions: updated_sessions}}
  end
end
