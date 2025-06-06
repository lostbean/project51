defmodule Area51.Web.MysteryController do
  use Area51.Web, :controller

  alias Area51.LLM.MysteryAgent

  @doc """
  Creates an async mystery generation job.

  Expects JSON body with:
  - user_id (required)
  - theme (optional)
  - difficulty (optional, defaults to "medium")
  """
  def generate_async(conn, params) do
    with {:ok, user_id} <- extract_user_id(conn, params),
         {:ok, job} <-
           MysteryAgent.generate_mystery_async(%{
             user_id: user_id,
             theme: params["theme"],
             difficulty: params["difficulty"] || "medium"
           }) do
      json(conn, %{
        success: true,
        job: %{
          id: job.id,
          title: job.title,
          theme: job.theme,
          difficulty: job.difficulty,
          status: job.status,
          progress: job.progress,
          inserted_at: job.inserted_at
        }
      })
    else
      {:error, changeset} when is_struct(changeset, Ecto.Changeset) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          error: "Invalid parameters",
          details: format_changeset_errors(changeset)
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  @doc """
  Gets the status of a mystery generation job.
  """
  def job_status(conn, %{"job_id" => job_id}) do
    case MysteryAgent.get_mystery_job_status(job_id) do
      {:ok, job} ->
        json(conn, %{
          success: true,
          job: %{
            id: job.id,
            title: job.title,
            theme: job.theme,
            difficulty: job.difficulty,
            status: job.status,
            progress: job.progress,
            result: job.result,
            error_message: job.error_message,
            inserted_at: job.inserted_at,
            updated_at: job.updated_at
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Job not found"})
    end
  end

  @doc """
  Lists mystery generation jobs for a user.
  """
  def list_jobs(conn, params) do
    with {:ok, user_id} <- extract_user_id(conn, params) do
      jobs = MysteryAgent.list_mystery_jobs(user_id)

      json(conn, %{
        success: true,
        jobs:
          Enum.map(jobs, fn job ->
            %{
              id: job.id,
              title: job.title,
              theme: job.theme,
              difficulty: job.difficulty,
              status: job.status,
              progress: job.progress,
              result: job.result,
              error_message: job.error_message,
              inserted_at: job.inserted_at,
              updated_at: job.updated_at
            }
          end)
      })
    else
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  @doc """
  Cancels a mystery generation job.
  """
  def cancel_job(conn, %{"job_id" => job_id}) do
    case MysteryAgent.cancel_mystery_job(job_id) do
      {:ok, job} ->
        json(conn, %{
          success: true,
          message: "Job cancelled",
          job: %{
            id: job.id,
            status: job.status
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: inspect(reason)})
    end
  end

  # Private functions

  defp extract_user_id(conn, params) do
    # Try to get user_id from params first
    case params["user_id"] do
      user_id when is_binary(user_id) and user_id != "" ->
        {:ok, user_id}

      _ ->
        # Try to get from JWT token in Authorization header
        case get_req_header(conn, "authorization") do
          ["Bearer " <> token] ->
            extract_user_from_token(token)

          _ ->
            {:error, "Missing user_id or authorization header"}
        end
    end
  end

  defp extract_user_from_token(_token) do
    # For now, we'll accept the user_id from params
    # In a real implementation, you'd verify the JWT token here
    {:error, "Token verification not implemented - please provide user_id in request body"}
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
