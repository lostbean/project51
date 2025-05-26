defmodule Area51.LLM.Steps.GenerateMysteryDetailsStep do
  @moduledoc """
  Reactor Step to generate mystery details based on theme and difficulty.
  """
  use Reactor.Step

  alias Area51.LLM.Schemas.Mystery
  alias Instructor
  alias LangChain.PromptTemplate

  require OpenTelemetry.Tracer
  alias OpenTelemetry.Tracer

  require Logger

  @impl true
  def run(arguments, _context, _options) do
    Tracer.with_span "area51.llm.steps.generate_mystery_details_step" do
      try do
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

        start_time = System.monotonic_time()
        message_content = PromptTemplate.to_message!(mystery_prompt_template, arguments).content

        Tracer.set_attributes([
          {:"llm.generate_mystery.theme", arguments.theme},
          {:"llm.generate_mystery.difficulty", arguments.difficulty}
        ])

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
            end_time = System.monotonic_time()
            duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

            Tracer.set_attributes([
              {:"llm.generate_mystery.duration_ms", duration_ms},
              {:"llm.generate_mystery.title", mystery_data.title}
            ])

            {:ok, mystery_data}

          {:error, reason} ->
            Logger.error("Failed to generate mystery details. Reason: #{inspect(reason)}")

            Tracer.set_attributes([{:"llm.error", inspect(reason)}])
            # Return an error tuple
            {:error, reason}
        end
      rescue
        e ->
          Logger.error(
            "Unexpected error in GenerateMysteryDetailsStep: #{inspect(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
          )

          Tracer.set_attributes([
            {:"llm.step.error", inspect(e)},
            {:"llm.step.stacktrace", inspect(__STACKTRACE__)}
          ])

          # Return an error tuple
          {:error, e}
      end
    end
  end
end
