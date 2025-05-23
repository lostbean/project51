defmodule Area51.Web.LiveStateSocket do
  use Phoenix.Socket
  alias Area51.Web.InvestigationChannel
  alias Area51.Web.SessionListChannel

  channel InvestigationChannel.channel_name(), InvestigationChannel
  channel SessionListChannel.channel_name(), SessionListChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: "area51"
end
