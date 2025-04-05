defmodule Area51Web.LiveStateSocket do
  use Phoenix.Socket
  require Logger

  channel Area51Web.InvestigationChannel.channel_name(), Area51Web.InvestigationChannel
  channel Area51Web.SessionListChannel.channel_name(), Area51Web.SessionListChannel

  @impl true
  def connect(
        %{"user_id" => user_id, "username" => username, "avatar" => avatar},
        socket,
        _connect_info
      ) do
    # Auth-based connect with explicit user data
    {:ok, assign(socket, user_id: user_id, username: username, picture: avatar)}
  end

  # For development convenience, allow connection without auth
  # Remove or modify this in production
  def connect(_params, socket, _connect_info) do
    if Mix.env() == :dev do
      Logger.warning("DEV MODE: Allowing unauthenticated WebSocket connection")
      {:ok, assign(socket, user_id: "dev-user-id", username: "Developer")}
    else
      Logger.warning("WebSocket auth failed: No user data provided")
      :error
    end
  end

  @impl true
  def id(socket), do: "users_socket:#{socket.assigns.user_id}"
end
