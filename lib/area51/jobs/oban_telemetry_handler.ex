defmodule Area51.Jobs.ObanTelemetryHandler do
  @moduledoc """
  Generic telemetry handler for syncing Oban job events with Area51 job records.

  This handler listens to Oban telemetry events and dispatches them to
  job-specific handlers that implement the Area51.Jobs.JobHandler behavior.
  This design allows for loosely coupled, extensible job handling.
  """

  require Logger

  # Registry of job handlers - modules that implement JobHandler behavior
  @job_handlers [
    Area51.Jobs.MysteryGenerationJob.TelemetryHandler
  ]

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
  Handles Oban telemetry events and dispatches to appropriate job handlers.
  """
  def handle_event([:oban, :job, :start], _measurements, metadata, _config) do
    %{job: oban_job} = metadata

    with {handler_module, job_record} <- find_handler_for_job(oban_job) do
      Logger.debug("Oban job started", %{
        oban_job_id: oban_job.id,
        job_record_id: job_record.id,
        worker: oban_job.worker,
        handler: handler_module
      })

      handler_module.handle_job_start(job_record)
    end
  rescue
    e ->
      Logger.error("Error in Oban telemetry handler (job start)", %{
        error: Exception.format(:error, e, __STACKTRACE__),
        oban_job_id: Map.get(metadata, :job, %{}) |> Map.get(:id, "unknown")
      })
  end

  def handle_event([:oban, :job, :stop], _measurements, metadata, _config) do
    %{job: oban_job, result: result} = metadata

    with {handler_module, job_record} <- find_handler_for_job(oban_job) do
      Logger.debug("Oban job stopped", %{
        oban_job_id: oban_job.id,
        job_record_id: job_record.id,
        result: result,
        worker: oban_job.worker,
        handler: handler_module
      })

      case result do
        :ok ->
          handler_module.handle_job_completion(job_record, result)

        {:ok, _value} ->
          handler_module.handle_job_completion(job_record, result)

        {:error, reason} ->
          handler_module.handle_job_failure(job_record, reason)

        {:snooze, _seconds} ->
          # Job was snoozed, no action needed
          :ok

        _other ->
          Logger.warning("Unexpected Oban job result", %{
            oban_job_id: oban_job.id,
            job_record_id: job_record.id,
            result: result,
            handler: handler_module
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

  def handle_event([:oban, :job, :exception], _measurements, metadata, _config) do
    %{job: oban_job, kind: kind, reason: reason, stacktrace: stacktrace} = metadata

    with {handler_module, job_record} <- find_handler_for_job(oban_job) do
      Logger.error("Oban job exception", %{
        oban_job_id: oban_job.id,
        job_record_id: job_record.id,
        kind: kind,
        reason: inspect(reason),
        worker: oban_job.worker,
        handler: handler_module
      })

      handler_module.handle_job_exception(job_record, kind, reason, stacktrace)
    end
  rescue
    e ->
      Logger.error("Error in Oban telemetry handler (job exception)", %{
        error: Exception.format(:error, e, __STACKTRACE__),
        oban_job_id: Map.get(metadata, :job, %{}) |> Map.get(:id, "unknown")
      })
  end

  # Private functions

  defp find_handler_for_job(oban_job) do
    Enum.find_value(@job_handlers, fn handler_module ->
      if handler_module.worker_module() == oban_job.worker do
        find_job_record(handler_module, oban_job)
      end
    end)
  end

  defp find_job_record(handler_module, oban_job) do
    case handler_module.find_job_from_oban(oban_job) do
      nil -> nil
      job_record -> {handler_module, job_record}
    end
  end
end
