defmodule Area51.LLM.MysteryAgent do
  @moduledoc """
  An agent responsible for generating new mysteries for the Area 51 investigation game
  using a Large Language Model (LLM).

  This module provides both synchronous and asynchronous mystery generation.
  Synchronous generation uses the Reactor infrastructure directly, while
  asynchronous generation enqueues jobs with Oban for background processing.
  """

  alias Area51.LLM.Reactors.MysteryGenerationReactor
  alias Area51.LLM.Schemas.Mystery
  alias Area51.Jobs.MysteryGenerationJob

  require Logger

  @mystery_types [
    "alien technology discovery",
    "unexplained phenomena",
    "government cover-up",
    "missing scientists",
    "strange signals",
    "unusual biological entities"
  ]

  @doc """
  Generate a new mystery for an Area 51 investigation
  """
  def generate_mystery() do
    generate_mystery(nil, [])
  end

  def generate_mystery(topic) when is_binary(topic) or is_nil(topic) do
    generate_mystery(topic, [])
  end

  def generate_mystery(opts) when is_list(opts) do
    generate_mystery(nil, opts)
  end

  @doc """
  Generate a new mystery for an Area 51 investigation with a specific topic and options
  """
  def generate_mystery(topic, opts) when is_list(opts) do
    # If topic is provided, use it as the mystery type, otherwise select random type
    theme = if is_nil(topic) or topic == "", do: Enum.random(@mystery_types), else: topic

    # Use a default difficulty for backward compatibility
    difficulty = "medium"

    reactor_opts =
      if Keyword.has_key?(opts, :otel_span_ctx) do
        [otel_span_ctx: Keyword.get(opts, :otel_span_ctx)]
      else
        []
      end

    case Reactor.run(
           MysteryGenerationReactor,
           %{theme: theme, difficulty: difficulty},
           reactor_opts
         ) do
      {:ok, %Mystery{} = mystery} ->
        # Transform the Mystery struct to match the expected return format for backward compatibility
        {:ok,
         %{
           title: mystery.title,
           description: mystery.description,
           solution: mystery.solution,
           starting_narrative: mystery.narrative
         }}

      {:error, reason} ->
        {:error, reason}

      other ->
        Logger.warning("Unexpected result from MysteryGenerationReactor: #{inspect(other)}")
        {:error, "Unexpected result from mystery generation"}
    end
  rescue
    e ->
      Exception.format(:error, e, __STACKTRACE__) |> Logger.warning()
      {:error, e}
  end

  @doc """
  Generate a new mystery for an Area 51 investigation with a specific topic

  This function is kept for backward compatibility and delegates to generate_mystery/1
  """
  def generate_mystery_with_topic(topic, opts \\ []) do
    generate_mystery(topic, opts)
  end

  @doc """
  Generate a mystery asynchronously using Oban jobs.

  Returns {:ok, job} where job is the Area51.Data.Jobs.MysteryGenerationJob record.
  The actual mystery generation happens in the background.

  Options:
  - `:user_id` - Required. ID of the user requesting the mystery
  - `:theme` - Optional. Specific theme, otherwise random
  - `:difficulty` - Optional. Difficulty level (default: "medium")
  """
  def generate_mystery_async(opts) when is_list(opts) do
    user_id = Keyword.fetch!(opts, :user_id)
    theme = Keyword.get(opts, :theme) || Enum.random(@mystery_types)
    difficulty = Keyword.get(opts, :difficulty, "medium")

    attrs = %{
      theme: theme,
      difficulty: difficulty,
      user_id: user_id
    }

    MysteryGenerationJob.create_mystery_generation_job(attrs)
  end

  def generate_mystery_async(%{user_id: user_id} = attrs) do
    attrs = %{
      theme: attrs[:theme] || Enum.random(@mystery_types),
      difficulty: attrs[:difficulty] || "medium",
      user_id: user_id
    }

    MysteryGenerationJob.create_mystery_generation_job(attrs)
  end

  @doc """
  Get the status of a mystery generation job.
  """
  def get_mystery_job_status(job_id) do
    case MysteryGenerationJob.get_mystery_generation_job(job_id) do
      nil -> {:error, :not_found}
      job -> {:ok, job}
    end
  end

  @doc """
  List mystery generation jobs for a user.

  Options are passed through to MysteryGenerationJob.list_mystery_generation_jobs/2
  """
  def list_mystery_jobs(user_id, opts \\ []) do
    MysteryGenerationJob.list_mystery_generation_jobs(user_id, opts)
  end

  @doc """
  Get jobs for the sidebar display: running + last N completed.
  """
  def get_jobs_for_sidebar(user_id, completed_limit \\ 10) do
    MysteryGenerationJob.list_jobs_for_sidebar(user_id, completed_limit)
  end

  @doc """
  Cancel a mystery generation job.
  """
  def cancel_mystery_job(job_id) do
    MysteryGenerationJob.cancel_mystery_generation_job(job_id)
  end
end
