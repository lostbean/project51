defmodule Area51.Jobs.MysteryGenerationJob do
  @moduledoc """
  Schema for tracking mystery generation jobs.

  This schema maintains user-facing job metadata and state while linking to the
  corresponding Oban.Job for execution tracking.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer(),
          title: String.t(),
          theme: String.t(),
          difficulty: String.t(),
          status: atom(),
          user_id: String.t(),
          oban_job_id: integer() | nil,
          result: map() | nil,
          error_message: String.t() | nil,
          progress: integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @status_values ~w(pending running completed failed cancelled)a

  schema "mystery_generation_jobs" do
    field :title, :string
    field :theme, :string
    field :difficulty, :string
    field :status, Ecto.Enum, values: @status_values, default: :pending
    field :user_id, :string
    field :oban_job_id, :integer
    field :result, :map
    field :error_message, :string
    field :progress, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [
      :title,
      :theme,
      :difficulty,
      :status,
      :user_id,
      :oban_job_id,
      :result,
      :error_message,
      :progress
    ])
    |> validate_required([:title, :theme, :difficulty, :user_id])
    |> validate_inclusion(:status, @status_values)
    |> validate_inclusion(:difficulty, ~w(easy medium hard))
    |> validate_number(:progress, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end

  @doc """
  Changeset for updating job status and related fields.
  """
  def status_changeset(job, attrs) do
    job
    |> cast(attrs, [:status, :result, :error_message, :progress])
    |> validate_inclusion(:status, @status_values)
    |> validate_number(:progress, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
  end
end
