defmodule Reactor.Middleware.TelemetryEventsMiddlewareTest do
  use ExUnit.Case, async: true

  alias Reactor.Middleware.TelemetryEventsMiddleware

  setup do
    # Capture telemetry events for testing
    test_pid = self()

    :telemetry.attach_many(
      "test-telemetry-handler",
      [
        [:custom, :prefix, :start],
        [:reactor, :start],
        [:reactor, :stop],
        [:reactor, :step, :run, :start],
        [:reactor, :step, :run, :stop],
        [:reactor, :step, :compensate, :start],
        [:reactor, :step, :compensate, :stop],
        [:reactor, :step, :undo, :start],
        [:reactor, :step, :undo, :stop]
      ],
      fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach("test-telemetry-handler")
    end)

    :ok
  end

  describe "init/1" do
    test "emits start event when enabled" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: true)

      context = %{reactor_name: "TestReactor"}

      assert {:ok, updated_context} = TelemetryEventsMiddleware.init(context)
      assert Map.has_key?(updated_context, :telemetry_start_time)
      assert Map.has_key?(updated_context, :reactor_name)

      # Check that telemetry event was emitted
      assert_receive {:telemetry_event, [:reactor, :start], measurements, metadata}
      assert Map.has_key?(measurements, :system_time)
      assert metadata.reactor_name == "TestReactor"
    end

    test "passes through context when disabled" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: false)

      context = %{reactor_name: "TestReactor"}

      assert {:ok, ^context} = TelemetryEventsMiddleware.init(context)

      # No telemetry event should be emitted
      refute_receive {:telemetry_event, _, _, _}, 100
    end
  end

  describe "event/3" do
    test "emits step events when enabled" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: true)

      step = %Reactor.Step{
        name: :test_step,
        impl: TestStep,
        arguments: [],
        async?: false
      }

      context = %{reactor_name: "TestReactor"}

      assert :ok = TelemetryEventsMiddleware.event(:run_start, step, context)

      assert_receive {:telemetry_event, [:reactor, :step, :run, :start], measurements, metadata}

      assert Map.has_key?(measurements, :system_time)
      assert metadata.reactor_name == "TestReactor"
      assert metadata.step_name == :test_step
      assert metadata.status == :ongoing

      assert :ok = TelemetryEventsMiddleware.event(:run_complete, step, context)

      assert_receive {:telemetry_event, [:reactor, :step, :run, :stop], measurements, metadata}

      assert metadata.step_name == :test_step
      assert metadata.status == :success
    end

    test "no events when disabled" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: false)

      step = %Reactor.Step{
        name: :test_step,
        impl: TestStep,
        arguments: []
      }

      context = %{reactor_name: "TestReactor"}

      assert :ok = TelemetryEventsMiddleware.event(:run_start, step, context)

      refute_receive {:telemetry_event, _, _, _}, 100
    end
  end

  describe "complete/2" do
    test "emits stop event when enabled" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: true)

      result = %{success: true}

      context = %{
        telemetry_start_time: System.monotonic_time(),
        reactor_name: "TestReactor"
      }

      assert {:ok, ^result} = TelemetryEventsMiddleware.complete(result, context)

      assert_receive {:telemetry_event, [:reactor, :stop], measurements, metadata}
      assert Map.has_key?(measurements, :duration)
      assert metadata.reactor_name == "TestReactor"
      assert metadata.status == :success
    end

    test "passes through when disabled" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: false)

      result = %{success: true}
      context = %{}

      assert {:ok, ^result} = TelemetryEventsMiddleware.complete(result, context)

      refute_receive {:telemetry_event, _, _, _}, 100
    end
  end

  describe "error/2" do
    test "emits error event when enabled" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: true)

      error = :test_error

      context = %{
        telemetry_start_time: System.monotonic_time(),
        reactor_name: "TestReactor"
      }

      assert {:error, ^error} = TelemetryEventsMiddleware.error(error, context)

      assert_receive {:telemetry_event, [:reactor, :stop], measurements, metadata}
      assert Map.has_key?(measurements, :duration)
      assert metadata.reactor_name == "TestReactor"
      assert metadata.status == :error
    end

    test "passes through when disabled" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: false)

      error = :test_error
      context = %{}

      assert {:error, ^error} = TelemetryEventsMiddleware.error(error, context)

      refute_receive {:telemetry_event, _, _, _}, 100
    end
  end

  describe "halt/1" do
    test "emits halt event when enabled" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: true)

      context = %{
        telemetry_start_time: System.monotonic_time(),
        reactor_name: "TestReactor"
      }

      assert {:ok, updated_context} = TelemetryEventsMiddleware.halt(context)
      assert Map.has_key?(updated_context, :telemetry_cleaned)

      assert_receive {:telemetry_event, [:reactor, :stop], measurements, metadata}
      assert Map.has_key?(measurements, :duration)
      assert metadata.reactor_name == "TestReactor"
    end

    test "passes through when disabled" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: false)

      context = %{}

      assert {:ok, ^context} = TelemetryEventsMiddleware.halt(context)

      refute_receive {:telemetry_event, _, _, _}, 100
    end
  end

  describe "metadata inclusion" do
    test "includes additional metadata when configured" do
      Application.put_env(:area51, TelemetryEventsMiddleware,
        enabled: true,
        include_metadata: true
      )

      result = %{data: "test"}

      context = %{
        telemetry_start_time: System.monotonic_time(),
        reactor_name: "TestReactor",
        correlation_id: "test-123",
        user_id: "user-456"
      }

      assert {:ok, ^result} = TelemetryEventsMiddleware.complete(result, context)

      assert_receive {:telemetry_event, [:reactor, :stop], measurements, metadata}
      assert metadata.correlation_id == "test-123"
      assert metadata.user_id == "user-456"
      assert metadata.result_type == :map
      assert metadata.result_size == 1
    end

    test "excludes additional metadata when configured" do
      Application.put_env(:area51, TelemetryEventsMiddleware,
        enabled: true,
        include_metadata: false
      )

      result = %{data: "test"}

      context = %{
        telemetry_start_time: System.monotonic_time(),
        reactor_name: "TestReactor",
        correlation_id: "test-123"
      }

      assert {:ok, ^result} = TelemetryEventsMiddleware.complete(result, context)

      assert_receive {:telemetry_event, [:reactor, :stop], measurements, metadata}
      refute Map.has_key?(metadata, :correlation_id)
      refute Map.has_key?(metadata, :result_type)
    end
  end

  describe "custom event prefix" do
    test "uses custom event prefix when configured" do
      Application.put_env(:area51, TelemetryEventsMiddleware,
        enabled: true,
        event_prefix: [:custom, :prefix]
      )

      context = %{reactor_name: "TestReactor"}

      assert {:ok, _} = TelemetryEventsMiddleware.init(context)

      assert_receive {:telemetry_event, [:custom, :prefix, :start], _, _}
    end
  end

  describe "error handling" do
    test "gracefully handles exceptions" do
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: true)

      # Should not crash even if telemetry operations fail
      context = %{reactor_name: "TestReactor"}

      assert {:ok, _} = TelemetryEventsMiddleware.init(context)
    end
  end
end
