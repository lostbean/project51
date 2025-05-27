defmodule Area51.LLM.Steps.ExtractCluesStep do
  @moduledoc """
  Reactor Step to extract clues from the generated narrative.
  """
  use Reactor.Step

  alias Area51.LLM.Schemas.Clue
  alias Area51.LLM.Schemas.Clues
  alias Instructor
  alias LangChain.PromptTemplate

  require Logger

  @impl true
  def run(arguments, _context, _options) do
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
        # Return both narrative_response and clues as expected by the investigation agent
        {:ok, %{narrative_response: arguments.narrative_response, clues: clues}}

      {:error, _reason} ->
        # Return empty clues on error. The middleware will log the original error.
        {:ok, %{narrative_response: arguments.narrative_response, clues: []}}
    end
  rescue
    e ->
      Exception.format(:error, e, __STACKTRACE__) |> Logger.warning()
      {:error, e}
  end
end
