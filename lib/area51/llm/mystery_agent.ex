defmodule Area51LLM.MysteryAgent do
  @moduledoc """
  An agent responsible for generating new mysteries for the Area 51 investigation game
  using a Large Language Model (LLM).

  This module now uses the Reactor infrastructure with the MysteryGenerationReactor
  to create mysteries with a title, description, solution, and starting narrative.
  It can generate mysteries based on a randomly selected type or a specified topic.
  """

  alias Area51LLM.Reactors.MysteryGenerationReactor
  alias Area51LLM.Schemas.Mystery

  require Logger

  @mystery_types [
    "alien technology discovery",
    "unexplained phenomena",
    "government cover-up",
    "missing scientists",
    "strange signals",
    "unusual biological entities"
  ]

  @doc """
  Generate a new mystery for an Area 51 investigation
  """
  def generate_mystery do
    generate_mystery(nil)
  end

  @doc """
  Generate a new mystery for an Area 51 investigation with a specific topic
  """
  def generate_mystery(topic) do
    # If topic is provided, use it as the mystery type, otherwise select random type
    theme = if is_nil(topic) or topic == "", do: Enum.random(@mystery_types), else: topic

    # Use a default difficulty for backward compatibility
    difficulty = "medium"

    try do
      case Reactor.run(MysteryGenerationReactor, %{theme: theme, difficulty: difficulty}) do
        {:ok, %Mystery{} = mystery} ->
          # Transform the Mystery struct to match the expected return format for backward compatibility
          {:ok,
           %{
             title: mystery.title,
             description: mystery.description,
             solution: mystery.solution,
             starting_narrative: mystery.narrative
           }}

        {:error, reason} ->
          Logger.error("Failed to generate mystery: #{inspect(reason)}")
          {:error, reason}

        other ->
          Logger.error("Unexpected result from MysteryGenerationReactor: #{inspect(other)}")
          {:error, "Unexpected result from mystery generation"}
      end
    rescue
      e ->
        Logger.error(
          "Exception in generate_mystery: #{inspect(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
        )

        {:error, "Exception occurred during mystery generation: #{inspect(e)}"}
    end
  end

  @doc """
  Generate a new mystery for an Area 51 investigation with a specific topic

  This function is kept for backward compatibility and delegates to generate_mystery/1
  """
  def generate_mystery_with_topic(topic) do
    generate_mystery(topic)
  end
end
