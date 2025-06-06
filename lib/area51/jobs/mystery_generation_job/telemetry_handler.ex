defmodule Area51.Jobs.MysteryGenerationJob.TelemetryHandler do
  @moduledoc """
  Telemetry handler for mystery generation jobs.

  Implements the Area51.Jobs.JobHandler behavior to provide
  job-specific handling for mystery generation job events.
  """

  @behaviour Area51.Jobs.JobHandler

  alias Area51.Jobs.MysteryGenerationJob
  require Logger

  @impl Area51.Jobs.JobHandler
  def worker_module, do: "Area51.LLM.Workers.MysteryGenerationWorker"

  @impl Area51.Jobs.JobHandler
  def find_job_from_oban(%{worker: "Area51.LLM.Workers.MysteryGenerationWorker"} = oban_job) do
    case MysteryGenerationJob.get_mystery_generation_job_by_oban_id(oban_job.id) do
      nil ->
        # Try to find by job args if oban_job_id wasn't set yet
        case oban_job.args do
          %{"job_id" => job_id} when is_integer(job_id) ->
            MysteryGenerationJob.get_mystery_generation_job(job_id)

          _ ->
            nil
        end

      mystery_job ->
        mystery_job
    end
  end

  def find_job_from_oban(_oban_job), do: nil

  @impl Area51.Jobs.JobHandler
  def handle_job_start(mystery_job) do
    # Update status to running if not already
    if mystery_job.status != :running do
      MysteryGenerationJob.update_job_status(mystery_job.id, :running)
    end

    :ok
  end

  @impl Area51.Jobs.JobHandler
  def handle_job_completion(mystery_job, _result) do
    # Job completed successfully, but we might have already updated
    # the status in the worker, so only update if still running
    if mystery_job.status == :running do
      MysteryGenerationJob.update_job_status(mystery_job.id, :completed, %{progress: 100})
    end

    :ok
  end

  @impl Area51.Jobs.JobHandler
  def handle_job_failure(mystery_job, reason) do
    MysteryGenerationJob.fail_job(mystery_job.id, inspect(reason))
    :ok
  end

  @impl Area51.Jobs.JobHandler
  def handle_job_exception(mystery_job, kind, reason, stacktrace) do
    error_msg = Exception.format(kind, reason, stacktrace)
    MysteryGenerationJob.fail_job(mystery_job.id, error_msg)
    :ok
  end
end
