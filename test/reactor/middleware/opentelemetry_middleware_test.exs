defmodule Reactor.Middleware.OpenTelemetryMiddlewareTest do
  use ExUnit.Case, async: true

  alias Reactor.Middleware.OpenTelemetryMiddleware

  describe "init/1" do
    test "initializes context when enabled" do
      # Mock configuration
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)

      context = %{reactor_name: "TestReactor"}

      assert {:ok, updated_context} = OpenTelemetryMiddleware.init(context)
      assert Map.has_key?(updated_context, :otel_start_time)
      assert Map.has_key?(updated_context, :reactor_name)
    end

    test "passes through context when disabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: false)

      context = %{reactor_name: "TestReactor"}

      assert {:ok, ^context} = OpenTelemetryMiddleware.init(context)
    end

    test "handles missing reactor name gracefully" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)

      context = %{}

      assert {:ok, updated_context} = OpenTelemetryMiddleware.init(context)
      assert updated_context.reactor_name == "unknown_reactor"
    end
  end

  describe "event/3" do
    test "handles step events when enabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)

      step = %Reactor.Step{
        name: :test_step,
        impl: TestStep,
        arguments: []
      }

      context = %{reactor_name: "TestReactor"}

      assert :ok = OpenTelemetryMiddleware.event(:run_start, step, context)
      assert :ok = OpenTelemetryMiddleware.event(:run_complete, step, context)
      assert :ok = OpenTelemetryMiddleware.event(:run_error, step, context)
    end

    test "no-ops when disabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: false)

      step = %Reactor.Step{
        name: :test_step,
        impl: TestStep,
        arguments: []
      }

      context = %{reactor_name: "TestReactor"}

      assert :ok = OpenTelemetryMiddleware.event(:run_start, step, context)
    end
  end

  describe "complete/2" do
    test "handles successful completion when enabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)

      result = %{success: true}
      context = %{otel_start_time: System.monotonic_time()}

      assert {:ok, ^result} = OpenTelemetryMiddleware.complete(result, context)
    end

    test "passes through when disabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: false)

      result = %{success: true}
      context = %{}

      assert {:ok, ^result} = OpenTelemetryMiddleware.complete(result, context)
    end
  end

  describe "error/2" do
    test "handles errors when enabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)

      error = :test_error
      context = %{otel_start_time: System.monotonic_time()}

      assert {:error, ^error} = OpenTelemetryMiddleware.error(error, context)
    end

    test "passes through when disabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: false)

      error = :test_error
      context = %{}

      assert {:error, ^error} = OpenTelemetryMiddleware.error(error, context)
    end
  end

  describe "halt/1" do
    test "handles halt when enabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)

      context = %{otel_start_time: System.monotonic_time()}

      assert {:ok, updated_context} = OpenTelemetryMiddleware.halt(context)
      assert Map.has_key?(updated_context, :otel_cleaned)
    end

    test "passes through when disabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: false)

      context = %{}

      assert {:ok, ^context} = OpenTelemetryMiddleware.halt(context)
    end
  end

  describe "process context" do
    test "get_process_context returns context when enabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)

      context = OpenTelemetryMiddleware.get_process_context()
      assert is_map(context) or is_nil(context)
    end

    test "get_process_context returns nil when disabled" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: false)

      assert is_nil(OpenTelemetryMiddleware.get_process_context())
    end

    test "set_process_context handles nil gracefully" do
      assert :ok = OpenTelemetryMiddleware.set_process_context(nil)
    end

    test "set_process_context handles valid context" do
      context = %{otel_context: :test, span_context: :test}
      assert :ok = OpenTelemetryMiddleware.set_process_context(context)
    end
  end

  describe "error handling" do
    test "gracefully handles exceptions in init" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)

      # This should not crash even if OpenTelemetry is not properly set up
      context = %{reactor_name: "TestReactor"}

      assert {:ok, _} = OpenTelemetryMiddleware.init(context)
    end

    test "gracefully handles exceptions in event handling" do
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)

      step = %Reactor.Step{
        name: :test_step,
        impl: TestStep,
        arguments: []
      }

      context = %{reactor_name: "TestReactor"}

      # Should not crash even if OpenTelemetry operations fail
      assert :ok = OpenTelemetryMiddleware.event(:run_start, step, context)
    end
  end
end
