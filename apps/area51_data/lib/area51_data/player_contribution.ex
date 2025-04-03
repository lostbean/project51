defmodule Area51Data.PlayerContribution do
  use Ecto.Schema
  import Ecto.Changeset

  alias Area51Data.Repo

  schema "player_contributions" do
    field :username, :string
    field :input, :string
    belongs_to :game_session, Area51Data.GameSession

    timestamps()
  end

  @doc false
  def changeset(player_contribution, attrs) do
    player_contribution
    |> cast(attrs, [:username, :input, :game_session_id])
    |> validate_required([:username, :input, :game_session_id])
  end

  def add_player_contribution(game_session_id, username, input) do
    Repo.get_by!(Area51Data.GameSession, id: game_session_id)
    |> Ecto.build_assoc(:player_contributions)
    |> cast(
      %{
        username: username,
        input: input
      },
      [:username, :input]
    )
    |> Repo.insert!()
  end
end
