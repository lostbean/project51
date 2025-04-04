defmodule Area51Data.Repo.Migrations.CreateGameSession do
  use Ecto.Migration

  def change do
    create table(:game_sessions) do
      add :narrative, :text
      add :title, :string
      add :description, :text
      add :solution, :text

      timestamps()
    end
  end
end
