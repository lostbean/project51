defmodule Area51.Web.ChannelInit do
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
