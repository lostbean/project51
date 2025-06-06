defmodule Area51.Data.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def change do
    Oban.Migration.up(version: 12)
  end
end