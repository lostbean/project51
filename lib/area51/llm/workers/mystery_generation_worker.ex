defmodule Area51.LLM.Workers.MysteryGenerationWorker do
  @moduledoc """
  Oban worker for generating mysteries asynchronously using the MysteryGenerationReactor.

  This worker processes mystery generation jobs in the background, providing
  progress updates and error handling for the async mystery creation process.
  """
  use Oban.Worker, queue: :mystery_generation, max_attempts: 3

  alias Area51.LLM.Reactors.MysteryGenerationReactor
  alias Area51.LLM.Schemas.Mystery
  alias Area51.Jobs.MysteryGenerationJob

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"theme" => theme, "difficulty" => difficulty} = args}) do
    job_id = args["job_id"]
    user_id = args["user_id"]

    try do
      # Update job status to running
      MysteryGenerationJob.update_job_status(job_id, :running)

      # Broadcast job status update
      Phoenix.PubSub.broadcast(
        Area51.Data.PubSub,
        "job_updates:#{user_id}",
        {:job_status_update, %{job_id: job_id, status: :running}}
      )

      Logger.info("Starting mystery generation", %{
        job_id: job_id,
        theme: theme,
        difficulty: difficulty,
        user_id: user_id
      })

      # Update progress to show we've started
      MysteryGenerationJob.update_job_progress(job_id, 10)

      # Run the mystery generation reactor
      case Reactor.run(MysteryGenerationReactor, %{theme: theme, difficulty: difficulty}) do
        {:ok, %Mystery{} = mystery} ->
          # Transform the Mystery struct to the expected format
          mystery_data = %{
            title: mystery.title,
            description: mystery.description,
            solution: mystery.solution,
            starting_narrative: mystery.narrative
          }

          # Update job with completion status and result
          MysteryGenerationJob.complete_job(job_id, mystery_data)

          # Broadcast completion
          Phoenix.PubSub.broadcast(
            Area51.Data.PubSub,
            "job_updates:#{user_id}",
            {:job_status_update,
             %{
               job_id: job_id,
               status: :completed,
               result: mystery_data,
               completed_at: DateTime.utc_now()
             }}
          )

          Logger.info("Mystery generation completed successfully", %{
            job_id: job_id,
            title: mystery.title
          })

          :ok

        {:error, reason} ->
          Logger.error("Mystery generation failed", %{
            job_id: job_id,
            error: inspect(reason)
          })

          # Update job with error status
          MysteryGenerationJob.fail_job(job_id, reason)

          # Broadcast failure
          Phoenix.PubSub.broadcast(
            Area51.Data.PubSub,
            "job_updates:#{user_id}",
            {:job_status_update,
             %{
               job_id: job_id,
               status: :failed,
               error: inspect(reason),
               failed_at: DateTime.utc_now()
             }}
          )

          {:error, reason}

        other ->
          error_msg = "Unexpected result from MysteryGenerationReactor: #{inspect(other)}"
          Logger.warning(error_msg, %{job_id: job_id})

          MysteryGenerationJob.fail_job(job_id, error_msg)

          Phoenix.PubSub.broadcast(
            Area51.Data.PubSub,
            "job_updates:#{user_id}",
            {:job_status_update,
             %{
               job_id: job_id,
               status: :failed,
               error: error_msg,
               failed_at: DateTime.utc_now()
             }}
          )

          {:error, error_msg}
      end
    rescue
      e ->
        error_msg = Exception.format(:error, e, __STACKTRACE__)

        Logger.error("Mystery generation worker crashed", %{
          job_id: job_id,
          error: error_msg
        })

        MysteryGenerationJob.fail_job(job_id, error_msg)

        Phoenix.PubSub.broadcast(
          Area51.Data.PubSub,
          "job_updates:#{user_id}",
          {:job_status_update,
           %{
             job_id: job_id,
             status: :failed,
             error: error_msg,
             failed_at: DateTime.utc_now()
           }}
        )

        {:error, e}
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    Logger.error("Invalid job arguments for MysteryGenerationWorker", %{args: args})
    {:error, "Missing required arguments: theme, difficulty, job_id, user_id"}
  end
end
