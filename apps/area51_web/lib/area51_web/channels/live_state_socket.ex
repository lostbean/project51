defmodule Area51Web.LiveStateSocket do
  use Phoenix.Socket

  channel Area51Web.InvestigationChannel.channel_name(), Area51Web.InvestigationChannel
  channel Area51Web.SessionListChannel.channel_name(), Area51Web.SessionListChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    # Authenticate user if needed
    {:ok, assign(socket, user_id: 1, username: "John")}
  end

  @impl true
  def id(socket), do: "users_socket:#{socket.assigns.user_id}"
end
