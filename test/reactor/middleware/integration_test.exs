defmodule Reactor.Middleware.IntegrationTest do
  # Make it sync because we a changing the logger level globally during the tests
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Reactor.Middleware.{
    OpenTelemetryMiddleware,
    StructuredLoggingMiddleware,
    TelemetryEventsMiddleware
  }

  # Test steps
  defmodule TestStep do
    use Reactor.Step

    @impl true
    def run(arguments, _context, _options) do
      Process.sleep(10)
      {:ok, %{input: arguments.input, processed: true, timestamp: DateTime.utc_now()}}
    end
  end

  defmodule FailingStep do
    use Reactor.Step

    @impl true
    def run(_arguments, _context, _options) do
      {:error, "Something went wrong"}
    end

    @impl true
    def compensate(_reason, _arguments, _context, _options) do
      :ok
    end
  end

  defmodule CompensatableStep do
    use Reactor.Step

    @impl true
    def run(arguments, _context, _options) do
      {:ok, %{input: arguments.input, processed: true}}
    end

    @impl true
    def compensate(_reason, _arguments, _context, _options) do
      :ok
    end

    @impl true
    def undo(_result, _arguments, _context, _options) do
      :ok
    end
  end

  # Test reactors
  defmodule SuccessfulReactor do
    use Reactor

    middlewares do
      middleware(OpenTelemetryMiddleware)
      middleware(StructuredLoggingMiddleware)
      middleware(TelemetryEventsMiddleware)
    end

    input(:input)

    step :test_step, TestStep do
      argument(:input, input(:input))
    end

    return(:test_step)
  end

  defmodule FailingReactor do
    use Reactor

    middlewares do
      middleware(OpenTelemetryMiddleware)
      middleware(StructuredLoggingMiddleware)
      middleware(TelemetryEventsMiddleware)
    end

    input(:input)

    step :failing_step, FailingStep do
      argument(:input, input(:input))
    end

    return(:failing_step)
  end

  defmodule SelectiveReactor do
    use Reactor

    middlewares do
      middleware(TelemetryEventsMiddleware)
    end

    input(:input)

    step :test_step, TestStep do
      argument(:input, input(:input))
    end

    return(:test_step)
  end

  defmodule CompensationReactor do
    use Reactor

    middlewares do
      middleware(OpenTelemetryMiddleware)
      middleware(StructuredLoggingMiddleware)
      middleware(TelemetryEventsMiddleware)
    end

    input(:input)

    step :compensatable_step, CompensatableStep do
      argument(:input, input(:input))
    end

    step :failing_step, FailingStep do
      argument(:input, result(:compensatable_step))
    end

    return(:failing_step)
  end

  setup do
    # Reset configuration for each test

    Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)
    Application.put_env(:area51, StructuredLoggingMiddleware, enabled: true, log_level: :warning)
    Application.put_env(:area51, TelemetryEventsMiddleware, enabled: true)

    # Capture telemetry events
    test_pid = self()

    :telemetry.attach_many(
      "integration-test-handler",
      [
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
      :telemetry.detach("integration-test-handler")
    end)

    :ok
  end

  describe "middleware stack integration" do
    test "all middleware work together for successful reactor execution" do
      # Execute reactor with all middleware enabled
      log_output =
        capture_log(fn ->
          # Set logger level during the test
          initial_log_level = Application.get_env(:logger, :level)
          Logger.configure(level: :warning)

          result = Reactor.run(SuccessfulReactor, %{input: "test"})
          assert {:ok, %{input: "test", processed: true}} = result

          Logger.configure(level: initial_log_level)
        end)

      # Verify logging output
      assert log_output =~ "Reactor starting"
      assert log_output =~ "Step event"
      assert log_output =~ "test_step"
      assert log_output =~ "run_start"
      assert log_output =~ "run_complete"
      assert log_output =~ "Reactor completed successfully"

      # Verify telemetry events
      assert_receive {:telemetry_event, [:reactor, :start], _, metadata}
      assert metadata.reactor_name == "Elixir.Reactor.Middleware.IntegrationTest.SuccessfulReactor"

      assert_receive {:telemetry_event, [:reactor, :step, :run, :start], _, metadata}
      assert metadata.step_name == :test_step
      assert metadata.status == :ongoing

      assert_receive {:telemetry_event, [:reactor, :step, :run, :stop], _, metadata}
      assert metadata.step_name == :test_step
      assert metadata.status == :success

      assert_receive {:telemetry_event, [:reactor, :stop], _, metadata}
      assert metadata.reactor_name == "Elixir.Reactor.Middleware.IntegrationTest.SuccessfulReactor"
      assert metadata.status == :success
    end

    test "all middleware handle errors gracefully" do
      log_output =
        capture_log(fn ->
          # Set logger level during the test
          initial_log_level = Application.get_env(:logger, :level)
          Logger.configure(level: :warning)

          result = Reactor.run(FailingReactor, %{input: "test"})
          assert {:error, _} = result

          Logger.configure(level: initial_log_level)
        end)

      # Verify error logging - check for error-related content
      assert log_output =~ "run_error" or log_output =~ "error"
      assert log_output =~ "failing_step"
      assert log_output =~ "Reactor execution failed" or log_output =~ "execution failed"

      # Verify telemetry events
      assert_receive {:telemetry_event, [:reactor, :start], _, _}
      assert_receive {:telemetry_event, [:reactor, :step, :run, :start], _, _}
      assert_receive {:telemetry_event, [:reactor, :step, :run, :stop], _, metadata}
      assert metadata.status == :error
      assert_receive {:telemetry_event, [:reactor, :stop], _, metadata}
      assert metadata.status == :error
    end

    test "middleware can be selectively disabled" do
      # Disable OpenTelemetry and logging, keep telemetry events
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: false)
      Application.put_env(:area51, StructuredLoggingMiddleware, enabled: false)
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: true)

      log_output =
        capture_log(fn ->
          # Set logger level during the test
          initial_log_level = Application.get_env(:logger, :level)
          Logger.configure(level: :warning)

          # Run reactor with only telemetry middleware enabled
          result = Reactor.run(SelectiveReactor, %{input: "test"})
          assert {:ok, %{input: "test", processed: true}} = result

          Logger.configure(level: initial_log_level)
        end)

      # No logging should occur (since logging middleware is disabled globally)
      refute log_output =~ "Reactor starting"
      refute log_output =~ "Reactor completed"

      # But telemetry events should still be emitted
      assert_receive {:telemetry_event, [:reactor, :start], _, _}
      assert_receive {:telemetry_event, [:reactor, :stop], _, _}
    end

    test "middleware handle compensation and undo operations" do
      log_output =
        capture_log(fn ->
          # Set logger level during the test
          initial_log_level = Application.get_env(:logger, :level)
          Logger.configure(level: :warning)

          # Run compensation reactor - it will execute the first step successfully
          # then fail on the second step, triggering compensation
          result = Reactor.run(CompensationReactor, %{input: "test"})
          assert {:error, _} = result

          Logger.configure(level: initial_log_level)
        end)

      # Verify compensation logging - the first step should execute and then be compensated
      assert log_output =~ "Step starting"
      assert log_output =~ "Step completed"
      assert log_output =~ "Step failed"
      assert log_output =~ "Step compensation completed"

      # Verify telemetry events for compensation
      assert_receive {:telemetry_event, [:reactor, :start], _, _}
      assert_receive {:telemetry_event, [:reactor, :step, :run, :start], _, metadata}
      assert metadata.step_name == :compensatable_step
      assert_receive {:telemetry_event, [:reactor, :step, :run, :stop], _, metadata}
      assert metadata.step_name == :compensatable_step
      assert metadata.status == :success
      assert_receive {:telemetry_event, [:reactor, :step, :run, :start], _, metadata}
      assert metadata.step_name == :failing_step
      assert_receive {:telemetry_event, [:reactor, :step, :run, :stop], _, metadata}
      assert metadata.step_name == :failing_step

      assert_receive {:telemetry_event, [:reactor, :step, :compensate, :start], _, metadata}
      assert metadata.step_name == :failing_step
      assert metadata.status == :ongoing

      assert_receive {:telemetry_event, [:reactor, :step, :compensate, :stop], _, metadata}
      assert metadata.step_name == :failing_step
      assert metadata.status == :success

      assert_receive {:telemetry_event, [:reactor, :stop], _, metadata}
      assert metadata.status == :error
    end

    test "middleware handle halt operations" do
      context = %{reactor_name: "HaltTestReactor", telemetry_start_time: System.monotonic_time()}

      log_output =
        capture_log(fn ->
          # Set logger level during the test
          initial_log_level = Application.get_env(:logger, :level)
          Logger.configure(level: :warning)

          # Init phase to establish context
          {:ok, context1} = OpenTelemetryMiddleware.init(context)
          {:ok, context2} = StructuredLoggingMiddleware.init(context1)
          {:ok, context3} = TelemetryEventsMiddleware.init(context2)

          # Simulate halt during execution
          {:ok, context4} = OpenTelemetryMiddleware.halt(context3)
          {:ok, context5} = StructuredLoggingMiddleware.halt(context4)
          {:ok, _context6} = TelemetryEventsMiddleware.halt(context5)

          Logger.configure(level: initial_log_level)
        end)

      # Verify halt logging
      assert log_output =~ "Reactor execution halted"

      # Verify telemetry events
      assert_receive {:telemetry_event, [:reactor, :start], _, _}
      assert_receive {:telemetry_event, [:reactor, :stop], _, metadata}
      assert metadata.reactor_name == "HaltTestReactor"
      assert metadata.status == :halt
    end
  end

  describe "performance impact" do
    test "disabled middleware has minimal overhead" do
      # Disable all middleware
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: false)
      Application.put_env(:area51, StructuredLoggingMiddleware, enabled: false)
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: false)

      # Measure time with disabled middleware using actual reactor execution
      {time_disabled, _} =
        :timer.tc(fn ->
          Enum.each(1..100, fn i ->
            result = Reactor.run(SelectiveReactor, %{input: "test_#{i}"})
            assert {:ok, _} = result
          end)
        end)

      # Disabled middleware should be very fast
      # Less than 2 second for 100 iterations
      assert time_disabled < 2_000_000
    end

    test "enabled middleware overhead is acceptable" do
      # Enable all middleware
      Application.put_env(:area51, OpenTelemetryMiddleware, enabled: true)
      Application.put_env(:area51, StructuredLoggingMiddleware, enabled: true)
      Application.put_env(:area51, TelemetryEventsMiddleware, enabled: true)

      # Measure time with enabled middleware
      {time_enabled, _} =
        :timer.tc(fn ->
          Enum.each(1..10, fn i ->
            result = Reactor.run(SuccessfulReactor, %{input: "test_#{i}"})
            assert {:ok, _} = result
          end)
        end)

      # Enabled middleware should still be reasonably fast
      # Less than 5 seconds for 10 iterations (allowing for logging/telemetry overhead)
      assert time_enabled < 5_000_000
    end
  end
end
