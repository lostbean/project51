defmodule Area51.Web.ChannelInit do
  @moduledoc """
  Provides utility functions for initializing Phoenix channels,
  primarily for generating and assigning unique channel IDs.

  This helps in correlating logs and traces for individual channel connections.
  """
  defp generate_request_id do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()}, 16_777_216)::24,
      :erlang.unique_integer()::32
    >>

    Base.url_encode64(binary)
  end

  def assign_channel_id(socket) do
    Phoenix.Socket.assign(socket, channel_id: generate_request_id())
  end
end
