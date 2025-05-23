defmodule Area51.Web.LiveStateSocket do
  use Phoenix.Socket

  channel Area51.Web.InvestigationChannel.channel_name(), Area51.Web.InvestigationChannel
  channel Area51.Web.SessionListChannel.channel_name(), Area51.Web.SessionListChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: "area51"
end
