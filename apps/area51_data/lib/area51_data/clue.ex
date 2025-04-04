defmodule Area51Data.Clue do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Area51Data.Repo

  schema "clues" do
    field :content, :string
    belongs_to :game_session, Area51Data.GameSession

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
    Repo.get_by!(Area51Data.GameSession, id: game_session_id)
    |> Ecto.build_assoc(:clues)
    |> cast(%{content: content}, [:content])
    |> Repo.insert!()
  end

  @doc """
  Get all clues for a game session
  """
  def get_clues_for_session(game_session_id) do
    Repo.all(from c in Area51Data.Clue, where: c.game_session_id == ^game_session_id)
  end
end
