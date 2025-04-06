defmodule Area51Web.LiveStateSocket do
  use Phoenix.Socket

  channel Area51Web.InvestigationChannel.channel_name(), Area51Web.InvestigationChannel
  channel Area51Web.SessionListChannel.channel_name(), Area51Web.SessionListChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: "area51"
end
