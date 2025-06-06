defmodule Area51.Jobs.ObanTelemetryHandler do
  @moduledoc """
  Telemetry handler for syncing Oban job events with Area51.Jobs records.

  This handler listens to Oban telemetry events and automatically updates
  our custom job records to keep them in sync with Oban's job states.
  """

  alias Area51.Jobs
  require Logger

  @doc """
  Attaches telemetry handlers for Oban events.

  Should be called during application startup.
  """
  def attach_handlers do
    events = [
      [:oban, :job, :start],
      [:oban, :job, :stop],
      [:oban, :job, :exception]
    ]

    :telemetry.attach_many(
      "area51-oban-sync",
      events,
      &__MODULE__.handle_event/4,
      nil
    )
  end

  @doc """
  Detaches telemetry handlers.
  """
  def detach_handlers do
    :telemetry.detach("area51-oban-sync")
  end

  @doc """
  Handles Oban telemetry events and syncs with our job records.
  """
  def handle_event([:oban, :job, :start], measurements, metadata, _config) do
    %{system_time: _start_time} = measurements
    %{job: job} = metadata

    case get_mystery_job_from_oban_job(job) do
      nil ->
        # Not one of our mystery generation jobs
        :ok

      mystery_job ->
        Logger.debug("Oban job started", %{
          oban_job_id: job.id,
          mystery_job_id: mystery_job.id,
          worker: job.worker
        })

        # Update status to running if not already
        if mystery_job.status != :running do
          Jobs.update_job_status(mystery_job.id, :running)
        end
    end
  rescue
    e ->
      Logger.error("Error in Oban telemetry handler (job start)", %{
        error: Exception.format(:error, e, __STACKTRACE__),
        oban_job_id: Map.get(metadata, :job, %{}) |> Map.get(:id, "unknown")
      })
  end

  def handle_event([:oban, :job, :stop], measurements, metadata, _config) do
    %{duration: _duration} = measurements
    %{job: job, result: result} = metadata

    case get_mystery_job_from_oban_job(job) do
      nil ->
        # Not one of our mystery generation jobs
        :ok

      mystery_job ->
        Logger.debug("Oban job stopped", %{
          oban_job_id: job.id,
          mystery_job_id: mystery_job.id,
          result: result,
          worker: job.worker
        })

        # Update based on the result
        case result do
          :ok ->
            # Job completed successfully, but we might have already updated
            # the status in the worker, so only update if still running
            if mystery_job.status == :running do
              Jobs.update_job_status(mystery_job.id, :completed, %{progress: 100})
            end

          {:ok, _value} ->
            # Same as :ok
            if mystery_job.status == :running do
              Jobs.update_job_status(mystery_job.id, :completed, %{progress: 100})
            end

          {:error, reason} ->
            # Job failed
            Jobs.fail_job(mystery_job.id, inspect(reason))

          {:snooze, _seconds} ->
            # Job was snoozed, keep it as running/pending
            :ok

          _other ->
            # Unexpected result
            Logger.warning("Unexpected Oban job result", %{
              oban_job_id: job.id,
              mystery_job_id: mystery_job.id,
              result: result
            })
        end
    end
  rescue
    e ->
      Logger.error("Error in Oban telemetry handler (job stop)", %{
        error: Exception.format(:error, e, __STACKTRACE__),
        oban_job_id: Map.get(metadata, :job, %{}) |> Map.get(:id, "unknown")
      })
  end

  def handle_event([:oban, :job, :exception], measurements, metadata, _config) do
    %{duration: _duration} = measurements
    %{job: job, kind: kind, reason: reason, stacktrace: stacktrace} = metadata

    case get_mystery_job_from_oban_job(job) do
      nil ->
        # Not one of our mystery generation jobs
        :ok

      mystery_job ->
        error_msg = Exception.format(kind, reason, stacktrace)

        Logger.error("Oban job exception", %{
          oban_job_id: job.id,
          mystery_job_id: mystery_job.id,
          kind: kind,
          reason: inspect(reason),
          worker: job.worker
        })

        # Mark job as failed
        Jobs.fail_job(mystery_job.id, error_msg)
    end
  rescue
    e ->
      Logger.error("Error in Oban telemetry handler (job exception)", %{
        error: Exception.format(:error, e, __STACKTRACE__),
        oban_job_id: Map.get(metadata, :job, %{}) |> Map.get(:id, "unknown")
      })
  end

  # Private functions

  defp get_mystery_job_from_oban_job(%{worker: "Area51.LLM.Workers.MysteryGenerationWorker"} = job) do
    case Jobs.get_mystery_generation_job_by_oban_id(job.id) do
      nil ->
        # Try to find by job args if oban_job_id wasn't set yet
        case job.args do
          %{"job_id" => job_id} when is_integer(job_id) ->
            Jobs.get_mystery_generation_job(job_id)

          _ ->
            nil
        end

      mystery_job ->
        mystery_job
    end
  end

  defp get_mystery_job_from_oban_job(_job), do: nil
end
