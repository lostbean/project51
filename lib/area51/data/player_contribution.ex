defmodule Area51.Data.PlayerContribution do
  @moduledoc """
  Defines the Ecto schema for `player_contributions`.

  This schema stores the input provided by a player (identified by `username`)
  during a specific `GameSession`. It includes functions for creating
  changesets and adding new contributions.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Area51.Data.Repo

  schema "player_contributions" do
    field :username, :string
    field :input, :string
    belongs_to :game_session, Area51.Data.GameSession

    timestamps()
  end

  @doc false
  def changeset(player_contribution, attrs) do
    player_contribution
    |> cast(attrs, [:username, :input, :game_session_id])
    |> validate_required([:username, :input, :game_session_id])
  end

  def add_player_contribution(game_session_id, username, input) do
    Repo.get_by!(Area51.Data.GameSession, id: game_session_id)
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
