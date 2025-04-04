defmodule Area51LLM.MysteryAgent do
  alias LangChain.Message
  alias Magus.GraphAgent
  alias Magus.AgentChain
  alias LangChain.PromptTemplate

  @mystery_types [
    "alien technology discovery",
    "unexplained phenomena",
    "government cover-up",
    "missing scientists",
    "strange signals",
    "unusual biological entities"
  ]

  @doc """
  Initialize the mystery generator agent
  """
  def init_mystery_generator_agent do
    %GraphAgent{
      name: "Area51 Mystery Generator",
      final_output_property: nil,
      initial_state: %{
        mystery_type: Enum.random(@mystery_types),
        mystery_title: nil,
        mystery_description: nil,
        solution: nil,
        starting_narrative: nil,
        mystery_data: nil
      }
    }
    |> GraphAgent.add_node(:generate_mystery, &generate_mystery_node/2)
    |> GraphAgent.set_entry_point(:generate_mystery)
    |> GraphAgent.add_edge(:generate_mystery, :end)
  end

  @doc """
  Generate a new mystery for an Area 51 investigation
  """
  def generate_mystery() do
    init_mystery_generator_agent()
    |> Magus.AgentExecutorLite.run()
    |> case do
      %{
        mystery_data: %{
          "description" => description,
          "solution" => solution,
          "starting_narrative" => starting_narrative,
          "title" => title
        }
      } ->
        {:ok,
         %{
           description: description,
           solution: solution,
           starting_narrative: starting_narrative,
           title: title
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Define the schema for the mystery JSON
  @mystery_schema %{
    "type" => "object",
    "properties" => %{
      "title" => %{
        "type" => "string",
        "description" => "The title of the mystery"
      },
      "description" => %{
        "type" => "string",
        "description" => "A brief description of the mystery (no spoilers)"
      },
      "solution" => %{
        "type" => "string",
        "description" => "The full solution to the mystery (hidden from players)"
      },
      "starting_narrative" => %{
        "type" => "string",
        "description" => "The initial narrative that sets the scene for the investigation"
      }
    }
  }

  # Node that generates the mystery components
  defp generate_mystery_node(chain, state) do
    mystery_template =
      ~S"""
      You are designing a collaborative investigation mystery game centered around Area 51.

      Create a compelling <%= @mystery_type %> mystery that will form the basis of our investigation.

      The mystery should have:
      1. A unique and intriguing premise related to Area 51
      2. Several clues that players can discover during investigation
      3. A coherent resolution that ties everything together
      4. Realistic but fascinating elements of science, military, and possibly extraterrestrial involvement

      Important: Do NOT share or hint at the actual solution in the description or starting narrative.
      The solution should be gradually uncovered through player investigation.
      """
      |> PromptTemplate.from_template!()

    {:ok, content, _response} =
      chain
      |> AgentChain.add_message(PromptTemplate.to_message!(mystery_template, state))
      |> AgentChain.ask_for_json_response(@mystery_schema)
      |> AgentChain.run()

    %{state | mystery_data: content}
  end
end
