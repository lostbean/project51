defmodule Area51LLM.InvestigationAgent do
  # Core dependencies
  alias Magus.GraphAgent
  alias Magus.AgentChain
  alias LangChain.PromptTemplate

  require OpenTelemetry.Tracer
  alias OpenTelemetry.Tracer
  alias OpenTelemetry.SemanticConventions.Trace

  @doc """
  Initialize the investigation agent
  """
  def init_investigation_agent do
    %GraphAgent{
      name: "Area51 Investigation Agent",
      final_output_property: nil,
      initial_state: %{
        narrative: nil,
        player_input: nil,
        narrative_response: nil,
        clues: []
      }
    }
    |> GraphAgent.add_node(:generate_narrative, &generate_narrative_node/2)
    |> GraphAgent.add_node(:extract_clues, &extract_clues_node/2)
    |> GraphAgent.set_entry_point(:generate_narrative)
    |> GraphAgent.add_edge(:generate_narrative, :extract_clues)
    |> GraphAgent.add_edge(:extract_clues, :end)
  end

  @doc """
  Generate a narrative response based on the current game state and player input
  """
  def generate_narrative(narrative, player_input, username) do
    Tracer.with_span "area51_llm.investigation_agent.generate_narrative", %{
      attributes: [
        {Trace.AI_REQUEST_MODEL, "investigation_agent"},
        {Trace.AI_REQUEST_USER, username},
        {:"llm.input_length", String.length(player_input)}
      ]
    } do
      agent = init_investigation_agent()

      initial_state = %{
        narrative: narrative,
        player_input: player_input,
        username: username,
        narrative_response: nil,
        clues: []
      }

      Magus.AgentExecutorLite.run(%{agent | initial_state: initial_state})
      |> case do
        %{narrative_response: response, clues: clues} ->
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

  # Node that generates the narrative response
  defp generate_narrative_node(chain, state) do
    Tracer.with_span "area51_llm.investigation_agent.generate_narrative_node" do
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

      {:ok, content, _response} =
        chain
        |> AgentChain.add_message(PromptTemplate.to_message!(narrative_template, state))
        |> AgentChain.run()

      end_time = System.monotonic_time()
      duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

      Tracer.set_attributes([
        {:"llm.narrative.duration_ms", duration_ms},
        {:"llm.narrative.length", String.length(content)}
      ])

      %{state | narrative_response: content}
    end
  end

  # Define the schema for extracting clues
  @clues_schema %{
    "type" => "object",
    "properties" => %{
      "clues" => %{
        "type" => "array",
        "description" => "List of important clues discovered in the narrative",
        "items" => %{
          "type" => "object",
          "properties" => %{
            "content" => %{
              "type" => "string",
              "description" => "The content of the clue"
            }
          }
        }
      }
    }
  }

  # Node that extracts clues from the generated narrative
  defp extract_clues_node(chain, state) do
    Tracer.with_span "area51_llm.investigation_agent.extract_clues_node" do
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

      {:ok, content, _response} =
        chain
        |> AgentChain.add_message(PromptTemplate.to_message!(extract_clues_template, state))
        |> AgentChain.ask_for_json_response(@clues_schema)
        |> AgentChain.run()

      end_time = System.monotonic_time()
      duration_ms = System.convert_time_unit(end_time - start_time, :native, :millisecond)

      clues = content["clues"] || []

      Tracer.set_attributes([
        {:"llm.extract_clues.duration_ms", duration_ms},
        {:"llm.extract_clues.count", length(clues)}
      ])

      %{state | clues: clues}
    end
  end
end
