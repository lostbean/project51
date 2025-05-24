defmodule Area51LLM.Reactors.MysteryGenerationReactor do
  @moduledoc """
  Mystery Generation reactor that orchestrates the creation of mystery details.

  This reactor takes a theme and difficulty level as inputs,
  generates mystery details, and returns the generated mystery data.
  """
  use Reactor

  alias Area51LLM.Steps.GenerateMysteryDetailsStep

  input(:theme)
  input(:difficulty)
  # Add other inputs like number_of_suspects, number_of_clues, etc. as needed

  step :generate_mystery_details, GenerateMysteryDetailsStep do
    argument(:theme, input(:theme))
    argument(:difficulty, input(:difficulty))
    # Pass other inputs as arguments here
  end

  return(:generate_mystery_details)
end
