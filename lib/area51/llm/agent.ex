defmodule Area51LLM.Agent do
  @moduledoc """
  Main facade module for LLM agents used in the Area 51 investigation game
  """

  @doc """
  Generate a narrative response based on the current game state and player input
  """
  def generate_narrative(narrative, player_input, username) do
    Area51LLM.InvestigationAgent.generate_narrative(narrative, player_input, username)
  end

  @doc """
  Generate a new mystery for an Area 51 investigation
  """
  def generate_mystery do
    Area51LLM.MysteryAgent.generate_mystery()
  end

  @doc """
  Generate a new mystery for an Area 51 investigation with a specific topic
  """
  def generate_mystery_with_topic(topic) do
    Area51LLM.MysteryAgent.generate_mystery_with_topic(topic)
  end
end
