defmodule Area51.LLM.Steps.GenerateMysteryDetailsStep do
  @moduledoc """
  Reactor Step to generate mystery details based on theme and difficulty.
  """
  use Reactor.Step

  alias Area51.LLM.Schemas.Mystery
  alias Instructor
  alias LangChain.PromptTemplate

  require Logger

  @impl true
  def run(arguments, _context, _options) do
    mystery_prompt_template =
      ~S"""
      You are a master storyteller and mystery writer.
      Your task is to generate the details for a new mystery investigation.

      Theme: <%= @theme %>
      Difficulty: <%= @difficulty %>
      # Add other parameters like number_of_suspects, number_of_clues if they are added to the reactor inputs

      Based on the provided theme and difficulty, please generate a compelling mystery.
      This should include a title, a detailed plot, a list of characters (suspects, victim, etc.),
      key locations, and a set of initial clues that investigators can find.
      Ensure the mystery is coherent and solvable given the difficulty level.
      The output should conform to the Mystery schema.
      """
      |> PromptTemplate.from_template!()

    message_content = PromptTemplate.to_message!(mystery_prompt_template, arguments).content

    case Instructor.chat_completion(
           # Or another suitable model
           model: "gpt-4o",
           response_model: Mystery,
           messages: [
             %{
               role: "user",
               content: message_content
             }
           ],
           # Optional: add retries for robustness
           max_retries: 2
         ) do
      {:ok, mystery_data = %Mystery{}} ->
        {:ok, mystery_data}

      {:error, reason} ->
        # Return an error tuple. The middleware will log the original error.
        {:error, reason}
    end
  rescue
    e ->
      Exception.format(:error, e, __STACKTRACE__) |> Logger.warning()
      {:error, e}
  end
end
