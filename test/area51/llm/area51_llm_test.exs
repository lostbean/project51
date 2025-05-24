defmodule Area51LLMTest do
  use ExUnit.Case, async: false
  alias Area51LLM.MysteryAgent
  alias Area51LLM.Schemas.Mystery

  setup do
    # Copy modules that we want to mock
    Mimic.copy(Instructor)
    Mimic.copy(Reactor)

    Mimic.stub(Instructor, :chat_completion, fn params ->
      case params[:response_model] do
        Area51LLM.Schemas.Mystery ->
          {:ok,
           %Area51LLM.Schemas.Mystery{
             title: "The Vanishing Scientists",
             description:
               "Several top-secret researchers have mysteriously disappeared from Area 51's underground laboratories.",
             solution:
               "The scientists discovered an alien artifact that transported them to another dimension.",
             narrative:
               "You arrive at the heavily guarded entrance to Area 51 as alarms blare in the distance."
           }}

        other ->
          raise "Received an unexpected module: #{inspect(other)}"
      end
    end)

    :ok
  end

  describe "MysteryAgent.generate_mystery/0" do
    test "generates a mystery with random topic" do
      result = MysteryAgent.generate_mystery()

      assert {:ok, mystery} = result

      assert %{
               title: "The Vanishing Scientists",
               description:
                 "Several top-secret researchers have mysteriously disappeared from Area 51's underground laboratories.",
               solution:
                 "The scientists discovered an alien artifact that transported them to another dimension.",
               starting_narrative:
                 "You arrive at the heavily guarded entrance to Area 51 as alarms blare in the distance."
             } = mystery
    end
  end

  describe "MysteryAgent.generate_mystery/1" do
    test "generates a mystery with specific topic" do
      result = MysteryAgent.generate_mystery("alien technology discovery")

      assert {:ok, mystery} = result

      assert %{
               title: "The Vanishing Scientists",
               description:
                 "Several top-secret researchers have mysteriously disappeared from Area 51's underground laboratories.",
               solution:
                 "The scientists discovered an alien artifact that transported them to another dimension.",
               starting_narrative:
                 "You arrive at the heavily guarded entrance to Area 51 as alarms blare in the distance."
             } = mystery
    end

    test "generates a mystery with nil topic (uses random)" do
      result = MysteryAgent.generate_mystery(nil)

      assert {:ok, mystery} = result

      assert %{
               title: "The Vanishing Scientists",
               description:
                 "Several top-secret researchers have mysteriously disappeared from Area 51's underground laboratories.",
               solution:
                 "The scientists discovered an alien artifact that transported them to another dimension.",
               starting_narrative:
                 "You arrive at the heavily guarded entrance to Area 51 as alarms blare in the distance."
             } = mystery
    end

    test "generates a mystery with empty string topic (uses random)" do
      result = MysteryAgent.generate_mystery("")

      assert {:ok, mystery} = result

      assert %{
               title: "The Vanishing Scientists",
               description:
                 "Several top-secret researchers have mysteriously disappeared from Area 51's underground laboratories.",
               solution:
                 "The scientists discovered an alien artifact that transported them to another dimension.",
               starting_narrative:
                 "You arrive at the heavily guarded entrance to Area 51 as alarms blare in the distance."
             } = mystery
    end
  end

  describe "MysteryAgent.generate_mystery_with_topic/1" do
    test "generates a mystery with specific topic (backward compatibility)" do
      result = MysteryAgent.generate_mystery_with_topic("government cover-up")

      assert {:ok, mystery} = result

      assert %{
               title: "The Vanishing Scientists",
               description:
                 "Several top-secret researchers have mysteriously disappeared from Area 51's underground laboratories.",
               solution:
                 "The scientists discovered an alien artifact that transported them to another dimension.",
               starting_narrative:
                 "You arrive at the heavily guarded entrance to Area 51 as alarms blare in the distance."
             } = mystery
    end

    test "handles nil topic (backward compatibility)" do
      result = MysteryAgent.generate_mystery_with_topic(nil)

      assert {:ok, mystery} = result
      assert is_map(mystery)
      assert Map.has_key?(mystery, :title)
      assert Map.has_key?(mystery, :description)
      assert Map.has_key?(mystery, :solution)
      assert Map.has_key?(mystery, :starting_narrative)
    end
  end

  describe "MysteryAgent error handling" do
    test "handles Instructor error" do
      Mimic.stub(Instructor, :chat_completion, fn params ->
        case params[:response_model] do
          Mystery -> {:error, "LLM service unavailable"}
          other -> raise "Received an unexpected module: #{inspect(other)}"
        end
      end)

      result = MysteryAgent.generate_mystery("test topic")

      # The error gets wrapped in a Reactor error structure
      assert {:error, %Reactor.Error.Invalid{}} = result
    end

    test "handles Reactor error" do
      # Mock Reactor.run to return an error
      Mimic.stub(Reactor, :run, fn _reactor, _inputs ->
        {:error, "Reactor execution failed"}
      end)

      result = MysteryAgent.generate_mystery("test topic")

      assert {:error, "Reactor execution failed"} = result
    end

    test "handles unexpected Reactor result" do
      # Mock Reactor.run to return an unexpected result
      Mimic.stub(Reactor, :run, fn _reactor, _inputs ->
        {:ok, "unexpected result"}
      end)

      result = MysteryAgent.generate_mystery("test topic")

      assert {:error, "Unexpected result from mystery generation"} = result
    end

    test "handles exceptions during generation" do
      # Mock Reactor.run to raise an exception
      Mimic.stub(Reactor, :run, fn _reactor, _inputs ->
        raise "Something went wrong"
      end)

      result = MysteryAgent.generate_mystery("test topic")

      assert {:error, error_message} = result
      assert String.contains?(error_message, "Exception occurred during mystery generation")
    end
  end
end
