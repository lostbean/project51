defmodule Area51.LLM.InvestigationAgent do
  @moduledoc """
  An LLM-powered agent that drives the Area 51 investigation game forward.

  This agent takes the current game narrative and player input, uses an LLM
  to generate the next segment of the story, and then employs the LLM again
  to extract relevant clues from the newly generated narrative. It uses
  `Reactor.Workflow` to orchestrate this multi-step LLM interaction and
  incorporates OpenTelemetry for tracing.
  """
  alias Area51.LLM.Reactors.InvestigationReactor
  alias Reactor

  @doc """
  Generate a narrative response based on the current game state and player input.
  """
  def generate_narrative(narrative, player_input, username) do
    inputs = %{
      narrative: narrative,
      player_input: player_input,
      username: username
    }

    case Reactor.run(InvestigationReactor, inputs) do
      {:ok, %{narrative_response: response, clues: clues}} ->
        {:ok, response, clues}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, "Unknown error in investigation agent"}
    end
  end
end
