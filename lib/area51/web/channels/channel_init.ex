defmodule Area51.Web.Channels.ChannelInit do
  @moduledoc """
  Initializes the channel state with common values.
  """

  def init(socket) do
    Map.take(socket.assigns, [:trace_id, :otel_span_ctx])
  end
end
