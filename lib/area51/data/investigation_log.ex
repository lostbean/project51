defmodule Area51.Data.InvestigationLog do
  @moduledoc """
  Defines the Ecto schema for `investigation_logs`.

  This schema is intended to store log entries or events that occur
  during a specific `GameSession`. Each log has an `entry` string and is
  associated with a game session.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "investigation_logs" do
    field :entry, :string
    belongs_to :game_session, Area51.Data.GameSession

    timestamps()
  end

  @doc false
  def changeset(investigation_log, attrs) do
    investigation_log
    |> cast(attrs, [:entry, :game_session_id])
    |> validate_required([:entry, :game_session_id])
  end
end
