defmodule Area51LLMTest do
  use ExUnit.Case
  doctest Area51LLM.Agent

  test "greets the world" do
    assert {:ok, _answer, _clues} =
             Area51LLM.Agent.generate_narrative("Make a moster", "What is its color?", "dev")
  end
end
