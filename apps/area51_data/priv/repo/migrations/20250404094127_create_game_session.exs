defmodule Area51Data.Repo.Migrations.CreateGameSession do
  use Ecto.Migration

  def change do
    create table(:game_sessions) do
      add :narrative, :string

      timestamps()
    end
  end
end
