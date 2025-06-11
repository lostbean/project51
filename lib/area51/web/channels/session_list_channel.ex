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
  alias OpenTelemetry.Span

  require OpenTelemetry.Tracer

  @channel_name "session_list"

  def channel_name, do: @channel_name

  @impl true
  def init(@channel_name, %{"token" => token}, socket) do
    # Create a span for the lifetime of the channel, and pass alnog in the socket. The terminate/1 will the span
    OpenTelemetry.Tracer.set_current_span(socket.assigns[:otel_span_ctx])
    span_ctx = OpenTelemetry.Tracer.start_span("live-state.#{@channel_name}")
    socket = socket |> assign(otel_span_ctx: span_ctx)

    OpenTelemetry.Tracer.with_span "live-state.#{@channel_name}.init" do
      # Authenticate using JWT token
      case Guardian.verify_and_get_user_info(token) do
        {:ok, user} ->
          :logger.info("Authenticated WebSocket connection for user: #{user.username}")

          # Subscribe to session creation events for real-time updates
          Phoenix.PubSub.subscribe(Area51.Data.PubSub, "session_list")

          # Fetch the list of available sessions
          sessions = GameSession.list_sessions_for_ui()

          state =
            %{
              sessions: sessions,
              username: user.username,
              error: nil
            }

          socket_with_assigns =
            socket
            |> assign(username: user.username)
            |> assign(otel_span_ctx: span_ctx)

          {:ok, state, socket_with_assigns}

        {:error, reason} ->
          :logger.warning("WebSocket auth failed: #{inspect(reason)}")
          OpenTelemetry.Span.end_span(span_ctx)
          :error
      end
    end
  end

  @impl true
  def handle_event("refresh_sessions" = event, _payload, state, socket) do
    OpenTelemetry.Tracer.with_span "live-state.#{@channel_name}.event.#{event}" do
      updated_sessions = GameSession.list_sessions_for_ui()
      {:noreply, %{state | sessions: updated_sessions}}
    end
  end

  def handle_event("create_session" = event, %{"topic" => topic}, state, socket) do
    OpenTelemetry.Tracer.with_span "live-state.#{@channel_name}.event.#{event}" do
      case Agent.generate_mystery_with_topic(topic) do
        {:ok, mystery_data} ->
          GameSession.create_game_session(mystery_data)
          updated_sessions = GameSession.list_sessions_for_ui()
          {:noreply, %{state | sessions: updated_sessions, error: nil}}

        {:error, _reason} ->
          {:noreply, %{state | error: "Failed to create new session"}}
      end
    end
  end

  def handle_event(unmatched_event, unmatched_event_payload, state, _socket) do
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

  @impl Phoenix.Channel
  def terminate(_reason, socket) do
    OpenTelemetry.Span.end_span(socket.assigns.otel_span_ctx)
    :ok
  end
end
