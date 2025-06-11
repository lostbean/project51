defmodule Area51.Web.LiveStateTestUtils do
  @moduledoc """
  Utilities for testing LiveState channels.
  """

  import Phoenix.ChannelTest
  import ExUnit.Assertions

  @doc """
  Joins a LiveState channel, asserts the initial "state:change" broadcast,
  and returns the joined socket and the initial state map.

  The `expected_initial_state` should be a map with atom keys, matching
  the state map defined in the channel's `init/3` callback.

  Optionally provide join_params to be used when joining the channel.
  """
  def join_and_assert_initial_state(
        socket,
        channel_module,
        topic_string,
        expected_initial_state,
        join_params \\ %{}
      ) do
    trace_context = %{
      trace_id: "test-trace-id",
      otel_span_ctx: :undefined
    }

    socket = Phoenix.Socket.assign(socket, trace_context)

    assert {:ok, %{}, joined_socket} =
             subscribe_and_join(socket, channel_module, topic_string, join_params)

    # Assert the initial full state broadcast
    assert_receive %Phoenix.Socket.Message{
                     event: "state:change",
                     topic: ^topic_string,
                     payload: %{
                       # Pinning the expected state for direct match
                       state: ^expected_initial_state,
                       version: 0
                     }
                   },
                   10_000

    # Return socket and the (confirmed) initial state
    {joined_socket, expected_initial_state}
  end

  @doc """
  Pushes a LiveState event (automatically prefixed with "lvs_evt:")
  and asserts the subsequent "state:patch" broadcast.

  `expected_patch_list` is a list of JSON Patch operations, e.g.,
  `[%{"op" => "replace", "path" => "/counter", "value" => 1}]`.
  """
  def push_event_and_assert_patch(
        socket,
        event_name_no_prefix,
        payload,
        expected_patch_list,
        expected_version
      ) do
    live_state_event_name = "lvs_evt:#{event_name_no_prefix}"
    # Get topic from the socket
    topic_string = socket.topic

    push(socket, live_state_event_name, payload)

    assert_receive %Phoenix.Socket.Message{
      event: "state:patch",
      topic: ^topic_string,
      payload: %{
        patch: ^expected_patch_list,
        version: ^expected_version
      }
    }

    # Indicate success
    :ok
  end
end
