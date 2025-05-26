defmodule Reactor.Middleware.UtilsTest do
  use ExUnit.Case, async: false
  alias Reactor.Middleware.Utils

  describe "step duration calculation" do
    test "calculates zero duration when no start time is stored" do
      step = %Reactor.Step{name: "test_step"}
      context = %{}

      assert Utils.calculate_step_duration(step, context) == 0
    end

    test "calculates actual duration when start time is stored" do
      step = %Reactor.Step{name: "test_step"}
      context = %{}

      # Store start time
      Utils.store_step_start_time(step.name)

      # Wait a small amount
      :timer.sleep(10)

      # Calculate duration
      duration = Utils.calculate_step_duration(step, context)

      # Should be at least 10ms but less than 50ms (allowing for test variance)
      assert duration >= 10
      assert duration < 50
    end

    test "cleanup removes step timing data" do
      step = %Reactor.Step{name: "test_step"}
      context = %{}

      # Store start time
      Utils.store_step_start_time(step.name)

      # Verify it's stored
      duration1 = Utils.calculate_step_duration(step, context)
      assert duration1 >= 0

      # Clean up
      Utils.cleanup_step_timing(step.name)

      # Should return 0 after cleanup
      duration2 = Utils.calculate_step_duration(step, context)
      assert duration2 == 0
    end

    test "handles multiple steps independently" do
      step1 = %Reactor.Step{name: "step_1"}
      step2 = %Reactor.Step{name: "step_2"}
      context = %{}

      # Store start time for step1
      Utils.store_step_start_time(step1.name)
      :timer.sleep(5)

      # Store start time for step2
      Utils.store_step_start_time(step2.name)
      :timer.sleep(5)

      # Calculate durations
      duration1 = Utils.calculate_step_duration(step1, context)
      duration2 = Utils.calculate_step_duration(step2, context)

      # Step1 should have longer duration
      assert duration1 > duration2
      assert duration1 >= 10
      assert duration2 >= 5

      assert Utils.calculate_step_duration(step1, context) == 0
      assert Utils.calculate_step_duration(step2, context) == 0
    end

    test "store_step_start_time accepts custom start time" do
      step = %Reactor.Step{name: "test_step"}
      context = %{}

      # Store custom start time (100ms ago)
      past_time = System.monotonic_time() - System.convert_time_unit(100, :millisecond, :native)
      Utils.store_step_start_time(step.name, past_time)

      duration = Utils.calculate_step_duration(step, context)

      # Should be approximately 100ms
      assert duration >= 95
      assert duration <= 105
    end

    test "handles string and atom step names consistently" do
      context = %{}

      # Store with atom
      Utils.store_step_start_time(:test_step)
      :timer.sleep(5)

      # Calculate with string name
      step_string = %Reactor.Step{name: "test_step"}
      duration1 = Utils.calculate_step_duration(step_string, context)

      # Both should give same result
      assert duration1 >= 5
    end
  end
end
