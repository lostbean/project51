defmodule Area51.LLM.Steps.GenerateNarrativeStep do
  @moduledoc """
  Reactor Step to generate the next part of the game narrative.
  """
  use Reactor.Step

  alias Instructor
  alias LangChain.PromptTemplate

  require Logger

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

    {:ok, content}
  rescue
    e ->
      Exception.format(:error, e, __STACKTRACE__) |> Logger.warning()
      {:error, e}
  end
end
