defmodule Area51LLMTest do
  use ExUnit.Case
  doctest Area51LLM.Agent

  test "greets the world" do
    assert {:ok, _} = Area51LLM.Agent.generate_narrative("Hey")
  end
end
