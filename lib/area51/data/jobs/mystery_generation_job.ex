defmodule Area51.Data.Jobs.MysteryGenerationJob do
  @moduledoc """
  Schema for tracking mystery generation jobs.

  This schema maintains user-facing job metadata and state while linking to the
  corresponding Oban.Job for execution tracking.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  alias Area51.Data.Repo

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

  # Data access functions

  @doc """
  Gets a mystery generation job by ID.
  """
  def get!(id) do
    Repo.get!(__MODULE__, id)
  end

  @doc """
  Gets a mystery generation job by ID, returns nil if not found.
  """
  def get(id) do
    Repo.get(__MODULE__, id)
  end

  @doc """
  Gets a mystery generation job by Oban job ID.
  """
  def get_by_oban_id(oban_job_id) do
    Repo.get_by(__MODULE__, oban_job_id: oban_job_id)
  end

  @doc """
  Lists mystery generation jobs for a user.

  Options:
  - `:limit` - Maximum number of jobs to return (default: 10)
  - `:status` - Filter by status
  - `:order` - Order by field (default: :inserted_at desc)
  """
  def list_for_user(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    status = Keyword.get(opts, :status)
    order = Keyword.get(opts, :order, desc: :inserted_at)

    query =
      from j in __MODULE__,
        where: j.user_id == ^user_id,
        order_by: ^order,
        limit: ^limit

    query =
      if status do
        from j in query, where: j.status == ^status
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Lists current running jobs plus the last N completed jobs for a user.

  This is specifically for the sidebar display: running jobs + last 10 completed.
  """
  def list_for_sidebar(user_id, completed_limit \\ 10) do
    # Get running jobs
    running_jobs =
      from j in __MODULE__,
        where: j.user_id == ^user_id and j.status in [:pending, :running],
        order_by: [desc: :inserted_at]

    # Get last N completed/failed jobs
    completed_jobs =
      from j in __MODULE__,
        where: j.user_id == ^user_id and j.status in [:completed, :failed, :cancelled],
        order_by: [desc: :inserted_at],
        limit: ^completed_limit

    %{
      running: Repo.all(running_jobs),
      completed: Repo.all(completed_jobs)
    }
  end

  @doc """
  Creates a new mystery generation job record.
  """
  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a mystery generation job.
  """
  def update(job, attrs) do
    job
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a mystery generation job status.
  """
  def update_status(job, attrs) do
    job
    |> status_changeset(attrs)
    |> Repo.update()
  end
end
