defmodule Area51LLM.Reactors.InvestigationReactor do
  @moduledoc """
  Investigation reactor that orchestrates narrative generation and clue extraction.

  This reactor takes narrative context, player input, and username as inputs,
  generates a narrative response, extracts clues from it, and returns both.
  """
  use Reactor

  alias Area51LLM.Steps.ExtractCluesStep
  alias Area51LLM.Steps.GenerateNarrativeStep

  input(:narrative)
  input(:player_input)
  input(:username)

  step :generate_narrative, GenerateNarrativeStep do
    argument(:narrative, input(:narrative))
    argument(:player_input, input(:player_input))
    argument(:username, input(:username))
  end

  step :extract_clues, ExtractCluesStep do
    argument(:narrative_response, result(:generate_narrative))
  end

  return(:extract_clues)
end
