defmodule Area51Data.InvestigationLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "investigation_logs" do
    field :entry, :string
    belongs_to :game_session, Area51Data.GameSession

    timestamps()
  end

  @doc false
  def changeset(investigation_log, attrs) do
    investigation_log
    |> cast(attrs, [:entry, :game_session_id])
    |> validate_required([:entry, :game_session_id])
  end
end
