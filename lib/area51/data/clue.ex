defmodule Area51.Data.Clue do
  @moduledoc """
  Defines the Ecto schema for `clues` and provides functions for
  managing clue data in the database.

  Each clue has `content` and is associated with a `GameSession`.
  This module allows adding new clues and retrieving all clues for a
  specific game session.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  alias Area51.Data.Repo

  schema "clues" do
    field :content, :string
    belongs_to :game_session, Area51.Data.GameSession

    timestamps()
  end

  @doc false
  def changeset(clue, attrs) do
    clue
    |> cast(attrs, [:content, :game_session_id])
    |> validate_required([:content, :game_session_id])
  end

  @doc """
  Add a new clue to the database
  """
  def add_clue(game_session_id, content) do
    Repo.get_by!(Area51.Data.GameSession, id: game_session_id)
    |> Ecto.build_assoc(:clues)
    |> cast(%{content: content}, [:content])
    |> Repo.insert!()
  end

  @doc """
  Get all clues for a game session
  """
  def get_clues_for_session(game_session_id) do
    Repo.all(from c in Area51.Data.Clue, where: c.game_session_id == ^game_session_id)
  end

  def data_to_core(%Area51.Data.Clue{} = clue) do
    %Area51.Core.Clue{
      content: clue.content
    }
  end
end
