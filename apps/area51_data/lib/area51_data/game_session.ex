defmodule Area51Data.GameSession do
  use Ecto.Schema
  import Ecto.Changeset

  alias Area51Data.Repo

  schema "game_sessions" do
    field :narrative, :string, default: ""
    has_many :clues, Area51Data.Clue
    has_many :player_contributions, Area51Data.PlayerContribution

    timestamps()
  end

  @doc false
  def changeset(game_session, attrs) do
    game_session
    |> cast(attrs, [:narrative])
    |> validate_required([:native])
  end

  def fetch_or_create_new_game_session(id, new_narrative) do
    Repo.get_by(Area51Data.GameSession, id: id) ||
      Repo.insert!(%Area51Data.GameSession{narrative: new_narrative})
  end
end
