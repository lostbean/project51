defmodule Area51Data.Repo.Migrations.CreateClues do
  use Ecto.Migration

  def change do
    create table(:clues) do
      add :content, :string
      add :game_session_id, references(:game_sessions, on_delete: :delete_all)

      timestamps()
    end

    create index(:clues, [:game_session_id])
  end
end
