defmodule Area51.Jobs.JobHandler do
  @moduledoc """
  Behavior for defining job-specific telemetry handlers.

  This behavior allows each job type to define how it should handle
  Oban telemetry events in a loosely coupled way.
  """

  @doc """
  Returns the Oban worker module name that this handler is responsible for.
  """
  @callback worker_module() :: String.t()

  @doc """
  Finds the job record associated with an Oban job.
  Returns nil if the job is not found or not handled by this module.
  """
  @callback find_job_from_oban(job :: %Oban.Job{}) :: struct() | nil

  @doc """
  Handles the job start event.
  Called when an Oban job starts executing.
  """
  @callback handle_job_start(job :: struct()) :: :ok

  @doc """
  Handles the job completion event.
  Called when an Oban job completes successfully.
  """
  @callback handle_job_completion(job :: struct(), result :: term()) :: :ok

  @doc """
  Handles the job failure event.
  Called when an Oban job fails or encounters an exception.
  """
  @callback handle_job_failure(job :: struct(), reason :: term()) :: :ok

  @doc """
  Handles the job exception event.
  Called when an Oban job raises an exception.
  """
  @callback handle_job_exception(
              job :: struct(),
              kind :: atom(),
              reason :: term(),
              stacktrace :: list()
            ) :: :ok
end
