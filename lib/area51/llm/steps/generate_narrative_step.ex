defmodule Area51LLM.Steps.GenerateNarrativeStep do
  @moduledoc """
  Reactor Step to generate the next part of the game narrative.
  """
  use Reactor.Step

  alias Instructor
  alias LangChain.PromptTemplate

  require OpenTelemetry.Tracer
  alias OpenTelemetry.Tracer

  defmodule Narrative do
    @moduledoc """
    Schema for narrative generation response from LLM.
    """
    use Ecto.Schema
    use Instructor

    @llm_doc """
    ## Field Descriptions:
    - narrative: narrative that continues the story
    """
    @primary_key false
    embedded_schema do
      field(:narrative, :string)
    end

    @impl true
    def validate_changeset(changeset) do
      changeset
      |> Ecto.Changeset.validate_required([:narrative])
    end
  end

  @impl true
  def run(arguments, _context, _options) do
    Tracer.with_span "area51_llm.steps.generate_narrative_step" do
      try do
        narrative_template =
          ~S"""
          You are the game master for an Area 51 investigation role-playing game. The players are a team of investigators
          trying to uncover the secrets of Area 51.

          Current narrative:
          <%= @narrative %>

          Player <%= @username %> has just contributed:
          <%= @player_input %>

          Generate the next part of the narrative that continues the story based on this input.
          Your response should be engaging, mysterious and advance the investigation in a logical way.
          Include interesting details about Area 51, possible alien encounters, or government secrets
          when appropriate.

          Keep your response to 2-3 paragraphs maximum.
          """
          |> PromptTemplate.from_template!()

        start_time = System.monotonic_time()
        message_content = PromptTemplate.to_message!(narrative_template, arguments).content

        {:ok, %Narrative{narrative: content}} =
          Instructor.chat_completion(
            model: "gpt-4o",
            response_model: Narrative,
            messages: [
              %{
                role: "user",
                content: message_content
              }
            ]
          )

        end_time = System.monotonic_time()
        duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

        Tracer.set_attributes([
          {:"llm.narrative.duration_ms", duration_ms},
          {:"llm.narrative.length", String.length(to_string(content))}
        ])

        {:ok, content}
      rescue
        e ->
          :logger.error(Exception.format(:error, e, __STACKTRACE__))
          reraise e, __STACKTRACE__
      end
    end
  end
end
