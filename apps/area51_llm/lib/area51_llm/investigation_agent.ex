defmodule Area51LLM.InvestigationAgent do
  # Core dependencies
  alias Magus.GraphAgent
  alias Magus.AgentChain
  alias LangChain.PromptTemplate

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
        {:ok, response, clues}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, "Unknown error in investigation agent"}
    end
  end

  # Node that generates the narrative response
  defp generate_narrative_node(chain, state) do
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

    {:ok, content, _response} =
      chain
      |> AgentChain.add_message(PromptTemplate.to_message!(narrative_template, state))
      |> AgentChain.run()

    %{state | narrative_response: content}
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

    {:ok, content, _response} =
      chain
      |> AgentChain.add_message(PromptTemplate.to_message!(extract_clues_template, state))
      |> AgentChain.ask_for_json_response(@clues_schema)
      |> AgentChain.run()

    %{state | clues: content["clues"]}
  end
end
