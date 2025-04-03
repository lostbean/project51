defmodule Area51Data.Repo.Migrations.CreatePlayerContributions do
  use Ecto.Migration

  def change do
    create table(:player_contributions) do
      add :username, :string
      add :input, :string
      add :game_session_id, references(:game_sessions, on_delete: :delete_all)

      timestamps()
    end

    create index(:player_contributions, [:game_session_id])
  end
end
