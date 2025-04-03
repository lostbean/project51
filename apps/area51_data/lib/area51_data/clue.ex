defmodule Area51Data.Clue do
  use Ecto.Schema
  import Ecto.Changeset

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
end
