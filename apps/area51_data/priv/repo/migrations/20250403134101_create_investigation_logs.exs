defmodule Area51Data.Repo.Migrations.CreateInvestigationLogs do
  use Ecto.Migration

  def change do
    create table(:investigation_logs) do
      add :entry, :string
      add :game_session_id, references(:game_sessions, on_delete: :delete_all)

      timestamps()
    end

    create index(:investigation_logs, [:game_session_id])
  end
end
