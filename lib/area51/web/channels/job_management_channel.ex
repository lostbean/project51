defmodule Area51.Web.JobManagementChannel do
  # Type issue with livestate
  @dialyzer {:nowarn_function, [build_new_state_message: 2, build_update_message: 3, join: 3]}

  @moduledoc """
  A `LiveState.Channel` responsible for managing mystery generation jobs.

  Provides real-time job updates and handles commands like creating new jobs,
  cancelling jobs, and getting job status updates.
  """
  use LiveState.Channel, web_module: Area51.Web

  alias Area51.LLM.MysteryAgent
  alias Area51.Web.Auth.Guardian
  alias Area51.Web.Channels.ChannelInit

  require Logger
  require OpenTelemetry.Tracer

  @channel_name "job_management"

  def channel_name, do: @channel_name

  @impl true
  def init(@channel_name, %{"token" => token}, socket) do
    initial_state = ChannelInit.init(socket)

    OpenTelemetry.Tracer.with_span "live-state.init.#{@channel_name}", %{} do
      # Authenticate using JWT token
      Guardian.verify_and_get_user_info(token)
      |> case do
        {:ok, user} ->
          Logger.info("Authenticated WebSocket connection for job management: #{user.username}")

          # Fetch current jobs for this user
          jobs = MysteryAgent.get_jobs_for_sidebar(user.external_id)

          state =
            initial_state
            |> Map.put(:running_jobs, jobs.running)
            |> Map.put(:completed_jobs, jobs.completed)
            |> Map.put(:user_id, user.external_id)
            |> Map.put(:username, user.username)
            |> Map.put(:error, nil)
            |> Map.delete(:otel_span_ctx)

          # Subscribe to job updates for this user
          Phoenix.PubSub.subscribe(Area51.Data.PubSub, "job_updates:#{user.external_id}")

          {:ok, state, assign(socket, user_id: user.external_id, username: user.username)}

        {:error, reason} ->
          Logger.warning("WebSocket auth failed for job management: #{inspect(reason)}")
          :error
      end
    end
  end

  @impl true
  def handle_message({:job_status_update, job_update}, state) do
    # Refresh job lists when we get updates
    user_id = state.user_id
    updated_jobs = MysteryAgent.get_jobs_for_sidebar(user_id)

    new_state = %{
      state
      | running_jobs: updated_jobs.running,
        completed_jobs: updated_jobs.completed,
        error: nil
    }

    # If job completed successfully and has a session_id, store it for frontend access
    new_state =
      case job_update do
        %{status: :completed, session_id: session_id} when is_integer(session_id) ->
          Map.put(new_state, :last_completed_session_id, session_id)

        _ ->
          new_state
      end

    {:noreply, new_state}
  end

  @impl true
  def handle_event("generate_mystery" = event, payload, state) do
    OpenTelemetry.Tracer.with_span "live-state.#{@channel_name}.event.#{event}", %{
      attributes: [
        {:event, event},
        {:user_id, state.user_id}
      ]
    } do
      # Extract parameters for mystery generation
      theme = payload["theme"]
      difficulty = payload["difficulty"] || "medium"

      attrs = %{
        user_id: state.user_id,
        theme: theme,
        difficulty: difficulty
      }

      case MysteryAgent.generate_mystery_async(attrs) do
        {:ok, job} ->
          Logger.info("Created mystery generation job", %{
            job_id: job.id,
            user_id: state.user_id,
            theme: job.theme,
            difficulty: job.difficulty
          })

          # Refresh job lists
          updated_jobs = MysteryAgent.get_jobs_for_sidebar(state.user_id)

          new_state = %{
            state
            | running_jobs: updated_jobs.running,
              completed_jobs: updated_jobs.completed,
              error: nil
          }

          {:noreply, new_state}

        {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
          error_msg = "Invalid parameters: #{format_changeset_errors(changeset)}"
          Logger.warning("Failed to create mystery job: #{error_msg}")

          {:noreply, %{state | error: error_msg}}

        {:error, reason} ->
          error_msg = "Failed to create mystery job: #{inspect(reason)}"
          Logger.error(error_msg)

          {:noreply, %{state | error: error_msg}}
      end
    end
  end

  @impl true
  def handle_event("cancel_job" = event, %{"job_id" => job_id}, state) do
    OpenTelemetry.Tracer.with_span "live-state.#{@channel_name}.event.#{event}", %{
      attributes: [
        {:event, event},
        {:user_id, state.user_id},
        {:job_id, job_id}
      ]
    } do
      case MysteryAgent.cancel_mystery_job(job_id) do
        {:ok, job} ->
          Logger.info("Cancelled mystery generation job", %{
            job_id: job.id,
            user_id: state.user_id
          })

          # Refresh job lists
          updated_jobs = MysteryAgent.get_jobs_for_sidebar(state.user_id)

          new_state = %{
            state
            | running_jobs: updated_jobs.running,
              completed_jobs: updated_jobs.completed,
              error: nil
          }

          {:noreply, new_state}

        {:error, reason} ->
          error_msg = "Failed to cancel job: #{inspect(reason)}"
          Logger.error(error_msg)

          {:noreply, %{state | error: error_msg}}
      end
    end
  end

  @impl true
  def handle_event("get_job_status" = event, %{"job_id" => job_id}, state) do
    OpenTelemetry.Tracer.with_span "live-state.#{@channel_name}.event.#{event}", %{
      attributes: [
        {:event, event},
        {:user_id, state.user_id},
        {:job_id, job_id}
      ]
    } do
      case MysteryAgent.get_mystery_job_status(job_id) do
        {:ok, _job} ->
          {:noreply, state}

        {:error, :not_found} ->
          {:noreply, state}
      end
    end
  end

  @impl true
  def handle_event(unmatched_event, unmatched_event_payload, _state) do
    Logger.warning(
      "Received unmatched event in job management: '#{unmatched_event}' with payload '#{inspect(unmatched_event_payload)}'"
    )

    {:noreply, %{error: "Unknown event: #{unmatched_event}"}}
  end

  # Private helper functions

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map_join("; ", fn {field, errors} -> "#{field}: #{Enum.join(errors, ", ")}" end)
  end
end
