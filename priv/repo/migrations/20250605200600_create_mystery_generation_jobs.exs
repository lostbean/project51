defmodule Area51.Data.Repo.Migrations.CreateMysteryGenerationJobs do
  use Ecto.Migration

  def change do
    create table(:mystery_generation_jobs) do
      add :title, :string, null: false
      add :theme, :string, null: false
      add :difficulty, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :user_id, :string, null: false
      add :oban_job_id, :bigint
      add :result, :map
      add :error_message, :text
      add :progress, :integer, default: 0

      timestamps()
    end

    create index(:mystery_generation_jobs, [:user_id])
    create index(:mystery_generation_jobs, [:status])
    create index(:mystery_generation_jobs, [:oban_job_id])
    create index(:mystery_generation_jobs, [:inserted_at])
  end
end