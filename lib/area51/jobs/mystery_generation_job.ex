defmodule Area51.Jobs.MysteryGenerationJob do
  @moduledoc """
  Context for managing mystery generation jobs.

  This module provides the API for creating, tracking, and managing mystery generation
  jobs, maintaining sync with Oban jobs for execution.
  """

  alias Area51.Data.Jobs.MysteryGenerationJob, as: MysteryGenerationJobData
  alias Area51.LLM.Workers.MysteryGenerationWorker

  require Logger

  @doc """
  Creates a new mystery generation job and enqueues it with Oban.

  Returns {:ok, job} on success, {:error, changeset} on failure.
  """
  def create_mystery_generation_job(attrs) do
    with {:ok, job} <- create_job_record(attrs),
         {:ok, oban_job} <- enqueue_oban_job(job) do
      # Update the job record with the Oban job ID
      MysteryGenerationJobData.update(job, %{oban_job_id: oban_job.id})
    end
  end

  @doc """
  Gets a mystery generation job by ID.
  """
  def get_mystery_generation_job!(id) do
    MysteryGenerationJobData.get!(id)
  end

  @doc """
  Gets a mystery generation job by ID, returns nil if not found.
  """
  def get_mystery_generation_job(id) do
    MysteryGenerationJobData.get(id)
  end

  @doc """
  Gets a mystery generation job by Oban job ID.
  """
  def get_mystery_generation_job_by_oban_id(oban_job_id) do
    MysteryGenerationJobData.get_by_oban_id(oban_job_id)
  end

  @doc """
  Lists mystery generation jobs for a user.

  Options:
  - `:limit` - Maximum number of jobs to return (default: 10)
  - `:status` - Filter by status
  - `:order` - Order by field (default: :inserted_at desc)
  """
  def list_mystery_generation_jobs(user_id, opts \\ []) do
    MysteryGenerationJobData.list_for_user(user_id, opts)
  end

  @doc """
  Lists current running jobs plus the last N completed jobs for a user.

  This is specifically for the sidebar display: running jobs + last 10 completed.
  """
  def list_jobs_for_sidebar(user_id, completed_limit \\ 10) do
    MysteryGenerationJobData.list_for_sidebar(user_id, completed_limit)
  end

  @doc """
  Updates a mystery generation job status.
  """
  def update_job_status(job_id, status, attrs \\ %{}) do
    job = MysteryGenerationJobData.get!(job_id)

    attrs = Map.put(attrs, :status, status)

    case MysteryGenerationJobData.update_status(job, attrs) do
      {:ok, updated_job} ->
        # Broadcast job status update
        Phoenix.PubSub.broadcast(
          Area51.Data.PubSub,
          "job_updates:#{updated_job.user_id}",
          {:job_status_update,
           %{
             job_id: updated_job.id,
             status: updated_job.status,
             progress: updated_job.progress,
             error_message: updated_job.error_message,
             result: updated_job.result,
             updated_at: updated_job.updated_at
           }}
        )

        {:ok, updated_job}

      error ->
        error
    end
  end

  @doc """
  Marks a job as completed with result data.
  """
  def complete_job(job_id, result) do
    update_job_status(job_id, :completed, %{result: result, progress: 100})
  end

  @doc """
  Marks a job as failed with error message.
  """
  def fail_job(job_id, error_message) do
    update_job_status(job_id, :failed, %{error_message: to_string(error_message)})
  end

  @doc """
  Updates job progress (0-100).
  """
  def update_job_progress(job_id, progress) when progress >= 0 and progress <= 100 do
    update_job_status(job_id, :running, %{progress: progress})
  end

  @doc """
  Cancels a mystery generation job.

  This will also attempt to cancel the Oban job if it hasn't started yet.
  """
  def cancel_mystery_generation_job(job_id) do
    job = MysteryGenerationJobData.get!(job_id)

    case job.oban_job_id do
      nil ->
        update_job_status(job_id, :cancelled)

      oban_job_id ->
        :ok = Oban.cancel_job(oban_job_id)
        update_job_status(job_id, :cancelled)
    end
  end

  # Private functions

  defp create_job_record(attrs) do
    # Generate a user-friendly title
    title = generate_job_title(attrs[:theme], attrs[:difficulty])

    attrs = Map.put(attrs, :title, title)

    MysteryGenerationJobData.create(attrs)
  end

  defp enqueue_oban_job(job) do
    job_args = %{
      "job_id" => job.id,
      "theme" => job.theme,
      "difficulty" => job.difficulty,
      "user_id" => job.user_id
    }

    job_args
    |> MysteryGenerationWorker.new(
      meta: %{
        "job_title" => job.title,
        "created_by" => job.user_id
      }
    )
    |> Oban.insert()
  end

  defp generate_job_title(theme, difficulty) do
    "Generating #{difficulty} mystery: #{theme}"
  end
end
