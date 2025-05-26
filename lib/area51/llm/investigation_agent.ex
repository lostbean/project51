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

  require OpenTelemetry.Tracer
  alias OpenTelemetry.SemanticConventions.Trace
  alias OpenTelemetry.Tracer

  @doc """
  Generate a narrative response based on the current game state and player input.
  """
  def generate_narrative(narrative, player_input, username) do
    Tracer.with_span "area51.llm.investigation_agent.generate_narrative", %{
      attributes: [
        {Trace.AI_REQUEST_MODEL, "investigation_agent"},
        {Trace.AI_REQUEST_USER, username},
        {:"llm.input_length", String.length(player_input)}
      ]
    } do
      inputs = %{
        narrative: narrative,
        player_input: player_input,
        username: username
      }

      case Reactor.run(InvestigationReactor, inputs) do
        {:ok, %{narrative_response: response, clues: clues}} ->
          Tracer.set_attributes([
            {:"llm.output_length", String.length(response)},
            {:"llm.clues_count", length(clues)}
          ])

          {:ok, response, clues}

        {:error, reason} ->
          Tracer.set_attributes([{:"llm.error", inspect(reason)}])
          {:error, reason}

        _ ->
          Tracer.set_attributes([{:"llm.error", "unknown"}])
          {:error, "Unknown error in investigation agent"}
      end
    end
  end
end
