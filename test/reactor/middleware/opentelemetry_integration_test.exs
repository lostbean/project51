defmodule Reactor.Middleware.OpenTelemetryIntegrationTest do
  use ExUnit.Case, async: false
  use Mimic

  alias OpenTelemetry.Tracer
  alias Reactor.Middleware.{OpenTelemetryMiddleware, Utils}

  describe "OpenTelemetry middleware integration with real Reactor execution" do
    setup do
      # Configure middleware as enabled for testing
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)

      # Clean up any process dictionary entries
      on_exit(fn ->
        Process.get_keys()
        |> Enum.filter(fn key -> match?({:step_timing, _}, key) end)
        |> Enum.each(&Process.delete/1)
      end)

      :ok
    end

    defmodule SimpleStep do
      @moduledoc "Simple step for testing"
      use Reactor.Step

      @impl true
      def run(arguments, _context, _options) do
        data = arguments.input
        # Simulate some work
        :timer.sleep(10)
        {:ok, %{result: data, processed_at: System.monotonic_time()}}
      end
    end

    defmodule CompensatableStep do
      @moduledoc "Step that supports compensation for testing"
      use Reactor.Step

      @impl true
      def run(arguments, _context, _options) do
        data = arguments.input
        :timer.sleep(5)
        {:ok, %{compensatable_result: data}}
      end

      @impl true
      def compensate(result, arguments, _context, _options) do
        # Simulate compensation work
        :timer.sleep(3)
        {:ok, %{compensated: result, original_input: arguments.input}}
      end

      @impl true
      def undo(result, arguments, _context, _options) do
        # Simulate undo work
        :timer.sleep(2)
        {:ok, %{undone: result, original_input: arguments.input}}
      end
    end

    defmodule TestReactor do
      @moduledoc "Test reactor with OpenTelemetry middleware"
      use Reactor

      middlewares do
        middleware(OpenTelemetryMiddleware)
      end

      input(:test_data)

      step :simple_processing, SimpleStep do
        argument(:input, input(:test_data))
      end

      step :compensatable_processing, CompensatableStep do
        argument(:input, result(:simple_processing))
      end

      return(:compensatable_processing)
    end

    defmodule FailingStep do
      use Reactor.Step

      @impl true
      def run(_arguments, _context, _options) do
        :timer.sleep(5)
        {:error, "Simulated failure"}
      end
    end

    defmodule FailingReactor do
      @moduledoc "Test reactor with OpenTelemetry middleware"
      use Reactor

      middlewares do
        middleware(OpenTelemetryMiddleware)
      end

      input(:test_data)

      step :failing_step, FailingStep do
        argument(:input, input(:test_data))
      end

      return(:failing_step)
    end

    test "middleware tracks all event types with proper timing and span operations" do
      test_pid = self()

      # Mock OpenTelemetry functions
      :meck.expect(:otel_tracer, :start_span, fn _ctx, span_name, _start_opts ->
        send(test_pid, {:otel_start_span_called, span_name})
        :mock_span_ctx
      end)

      expect(OpenTelemetry.Tracer, :end_span, fn _span_ctx ->
        send(test_pid, {:end_span_called})
        :ok
      end)

      expect(OpenTelemetry.Tracer, :set_current_span, fn _span_ctx ->
        send(test_pid, {:set_current_span_called})
        :ok
      end)

      expect(OpenTelemetry.Ctx, :get_current, fn ->
        :mock_ctx
      end)

      expect(OpenTelemetry.Ctx, :attach, fn _ctx ->
        :ok
      end)

      expect(Tracer, :set_attributes, fn attributes ->
        send(test_pid, {:set_attributes_called, attributes})

        # Verify we're getting duration measurements
        attribute_keys = Enum.map(attributes, fn {key, _value} -> key end)

        if :"step.duration_ms" in attribute_keys do
          duration_attr = Enum.find(attributes, fn {key, _} -> key == :"step.duration_ms" end)
          {_, duration} = duration_attr
          assert is_integer(duration)
          assert duration >= 0
        end

        :ok
      end)

      expect(Tracer, :end_span, fn _span_ctx ->
        send(test_pid, {:end_span_called})
        :ok
      end)

      expect(Tracer, :set_current_span, fn _span_ctx ->
        send(test_pid, {:set_current_span_called})
        :ok
      end)

      # Run the reactor with timing-enabled middleware
      test_data = %{message: "test input", timestamp: System.monotonic_time()}

      result = Reactor.run(TestReactor, %{test_data: test_data})

      assert {:ok, reactor_result} = result
      assert %{compensatable_result: %{result: ^test_data}} = reactor_result

      # Verify no timing data remains in process dictionary after completion
      timing_keys =
        Process.get_keys()
        |> Enum.filter(fn key -> match?({:step_timing, _}, key) end)

      assert timing_keys == [], "Step timing data should be cleaned up after reactor completion"

      # Verify we received some OpenTelemetry calls
      assert_received {:otel_start_span_called, "reactor.TestReactor.run"}
      assert_received {:otel_start_span_called, _}
      assert_received {:set_attributes_called, _}
      assert_received {:end_span_called}
    end

    test "middleware handles errors with proper span completion and error attributes" do
      test_pid = self()

      # Mock OpenTelemetry functions for error scenario
      :meck.expect(:otel_tracer, :start_span, fn _ctx, span_name, _start_opts ->
        send(test_pid, {:otel_start_span_called, span_name})
        :mock_span_ctx
      end)

      expect(Tracer, :end_span, fn _span_ctx ->
        send(test_pid, {:end_span_called})
        :ok
      end)

      expect(Tracer, :set_current_span, fn _span_ctx ->
        send(test_pid, {:set_current_span_called})
        :ok
      end)

      expect(OpenTelemetry.Ctx, :get_current, fn ->
        :mock_ctx
      end)

      expect(OpenTelemetry.Ctx, :attach, fn _ctx ->
        :ok
      end)

      expect(Tracer, :set_attributes, fn attributes ->
        send(test_pid, {:set_attributes_called, attributes})

        # Check for error attributes when present
        attribute_keys = Enum.map(attributes, fn {key, _value} -> key end)

        if :"step.error_type" in attribute_keys do
          error_type_attr = Enum.find(attributes, fn {key, _} -> key == :"step.error_type" end)
          {_, error_type} = error_type_attr
          assert is_binary(error_type)
        end

        if :"step.error_message" in attribute_keys do
          error_msg_attr = Enum.find(attributes, fn {key, _} -> key == :"step.error_message" end)
          {_, error_msg} = error_msg_attr
          assert is_binary(error_msg)
        end

        :ok
      end)

      # Run the failing reactor
      result = Reactor.run(FailingReactor, %{test_data: "test"})

      assert {:error, _error} = result

      # Verify timing cleanup even on error
      timing_keys =
        Process.get_keys()
        |> Enum.filter(fn key -> match?({:step_timing, _}, key) end)

      assert timing_keys == [], "Step timing data should be cleaned up even after errors"

      # Verify we received OpenTelemetry calls including error handling
      assert_received {:otel_start_span_called, "reactor.FailingReactor.run"}
      assert_received {:otel_start_span_called, _}
      assert_received {:set_attributes_called, _}
      assert_received {:end_span_called}
    end

    test "middleware correctly manages step timing across multiple operations" do
      # Verify that timing works for individual step duration calculations
      step = %Reactor.Step{name: "manual_test_step"}
      context = %{}

      # Store timing manually
      Utils.store_step_start_time(step.name)
      :timer.sleep(10)

      # Calculate duration
      duration = Utils.calculate_step_duration(step, context)

      # Verify reasonable duration and cleanup
      assert duration >= 10
      assert duration < 50

      # Verify timing was cleaned up
      timing_key = {:step_timing, "manual_test_step"}
      assert Process.get(timing_key) == nil
    end
  end
end
