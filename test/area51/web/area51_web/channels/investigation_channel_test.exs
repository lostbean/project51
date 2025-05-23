defmodule Area51.Web.InvestigationChannelTest do
  use Area51.Web.ChannelCase

  setup do
    # {:ok, _, socket} =
    #   Area51.Web.LiveStateSocket
    #   |> socket("user_id", %{user_id: 0})
    #   |> subscribe_and_join(Area51.Web.InvestigationChannel, "investigation:999")
    #
    # %{socket: socket}
  end

  # TODO: How test live-state???

  # test "ping replies with status ok", %{socket: socket} do
  #   ref = push(socket, "ping", %{"hello" => "there"})
  #   assert_reply ref, :ok, %{"hello" => "there"}
  # end
  #
  # test "shout broadcasts to test:lobby", %{socket: socket} do
  #   push(socket, "shout", %{"hello" => "all"})
  #   assert_broadcast "shout", %{"hello" => "all"}
  # end
  #
  # test "broadcasts are pushed to the client", %{socket: socket} do
  #   broadcast_from!(socket, "broadcast", %{"some" => "data"})
  #   assert_push "broadcast", %{"some" => "data"}
  # end
end
