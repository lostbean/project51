defmodule Area51GleamTest do
  use ExUnit.Case
  alias Area51.Gleam.Clue
  alias Area51.Gleam.InvestigationCard
  doctest Area51.Gleam

  test "can call Elixir code" do
    assert Clue.from_gleam({:clue, "some", "description"}) == %Clue{
             title: "some",
             description: "description"
           }
  end

  test "can call Gleam code" do
    assert :state.new_investigation_card(1, "title") |> InvestigationCard.from_gleam() ==
             %InvestigationCard{id: 1, title: "title"}
  end

  test "can call Gleam library" do
    assert :gleam@list.reverse([1, 2, 3]) == [3, 2, 1]
  end
end
