defmodule Area51.LLM.Steps.ExtractCluesStep do
  @moduledoc """
  Reactor Step to extract clues from the generated narrative.
  """
  use Reactor.Step

  alias Area51.LLM.Schemas.Clue
  alias Area51.LLM.Schemas.Clues
  alias Instructor
  alias LangChain.PromptTemplate

  require OpenTelemetry.Tracer
  alias OpenTelemetry.Tracer

  @impl true
  def run(arguments, _context, _options) do
    Tracer.with_span "area51.llm.steps.extract_clues_step" do
      extract_clues_template =
        ~S"""
        You are an expert at identifying important clues in a narrative.

        Here is the latest part of an Area 51 investigation narrative:
        <%= @narrative_response %>

        Identify any new clues or important pieces of information that were revealed in this narrative.
        A clue is any detail that might help investigators uncover the secrets of Area 51.

        If no clues were revealed, return an empty array.
        """
        |> PromptTemplate.from_template!()

      start_time = System.monotonic_time()
      message_content = PromptTemplate.to_message!(extract_clues_template, arguments).content

      case Instructor.chat_completion(
             model: "gpt-4o",
             response_model: Clues,
             messages: [
               %{
                 role: "user",
                 content: message_content
               }
             ]
           ) do
        {:ok, %Clues{clues: clues_list}} ->
          clues = Enum.map(clues_list, &%Clue{content: &1.content})
          end_time = System.monotonic_time()
          duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

          Tracer.set_attributes([
            {:"llm.extract_clues.duration_ms", duration_ms},
            {:"llm.extract_clues.count", length(clues)}
          ])

          # Return both narrative_response and clues as expected by the investigation agent
          {:ok, %{narrative_response: arguments.narrative_response, clues: clues}}

        {:error, reason} ->
          Tracer.set_attributes([{:"llm.error", inspect(reason)}])
          # Return empty clues on error
          {:ok, %{narrative_response: arguments.narrative_response, clues: []}}
      end
    end
  end
end
