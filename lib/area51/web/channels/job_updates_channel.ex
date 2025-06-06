defmodule Area51.Web.JobUpdatesChannel do
  @moduledoc """
  Phoenix channel for real-time job status updates.

  Handles subscriptions to job progress updates for mystery generation
  and other background jobs.
  """
  use Phoenix.Channel

  alias Area51.LLM.MysteryAgent

  require Logger

  @doc """
  Join a job updates channel for a specific user.

  Channel topic format: "job_updates:user_id"
  """
  def join("job_updates:" <> user_id, _payload, socket) do
    # For now, we'll allow any user to join their own channel
    # In a real app, you'd verify the user has permission to access this user_id

    socket = assign(socket, :user_id, user_id)

    # Send initial job state when user joins
    send(self(), :send_initial_jobs)

    Logger.info("User joined job updates channel", %{user_id: user_id})

    {:ok, socket}
  end

  def join("job_updates", _payload, _socket) do
    {:error, %{reason: "user_id required"}}
  end

  def join(_topic, _payload, _socket) do
    {:error, %{reason: "invalid topic"}}
  end

  @doc """
  Handle client requests for current job status.
  """
  def handle_in("get_jobs", _payload, socket) do
    user_id = socket.assigns.user_id
    jobs = MysteryAgent.get_jobs_for_sidebar(user_id)

    {:reply, {:ok, %{jobs: jobs}}, socket}
  end

  def handle_in("cancel_job", %{"job_id" => job_id}, socket) do
    case MysteryAgent.cancel_mystery_job(job_id) do
      {:ok, _job} ->
        {:reply, {:ok, %{message: "Job cancelled"}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  @doc """
  Handle job status updates from PubSub.
  """
  def handle_info({:job_status_update, job_update}, socket) do
    push(socket, "job_update", job_update)
    {:noreply, socket}
  end

  def handle_info(:send_initial_jobs, socket) do
    user_id = socket.assigns.user_id
    jobs = MysteryAgent.get_jobs_for_sidebar(user_id)

    push(socket, "initial_jobs", %{
      running: jobs.running,
      completed: jobs.completed
    })

    {:noreply, socket}
  end

  @doc """
  Handle channel termination.
  """
  def terminate(reason, socket) do
    user_id = socket.assigns[:user_id]

    Logger.info("User left job updates channel", %{
      user_id: user_id,
      reason: inspect(reason)
    })

    :ok
  end
end
