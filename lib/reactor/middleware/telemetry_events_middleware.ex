defmodule Reactor.Middleware.TelemetryEventsMiddleware do
  @moduledoc """
  Telemetry events middleware for emitting Elixir telemetry events during Reactor execution.

  This middleware provides:
  - Reactor-level events with comprehensive metadata
  - Step-level events with execution details
  - Custom metadata injection
  - Integration with Area51.Web.Telemetry

  ## Events Emitted

  ### Reactor Events
  - `[:reactor, :start]` - Reactor execution starts
  - `[:reactor, :stop]` - Reactor execution stops

  With `:status` metadata `[:success, :error, :halt, :ongoing]`

  ### Step Events
  - `[:reactor, :step, :start]` - Step process starts
  - `[:reactor, :step, :run, :start]` - Step execution starts
  - `[:reactor, :step, :compensate, :start]` - Step compensation starts
  - `[:reactor, :step, :undo, :start]` - Step undo starts
  - `[:reactor, :step, :stop]` - Step process starts
  - `[:reactor, :step, :run, :stop]` - Step execution stops
  - `[:reactor, :step, :compensate, :stop]` - Step compensation stops
  - `[:reactor, :step, :undo, :stop]` - Step undo stops

  With `:status` metadata `[:success, :error, :retry, :ongoing]` and `:number_of_retries` for tracking retry attempts

  ## Configuration

      config :area51, Reactor.Middleware.TelemetryEventsMiddleware,
        enabled: true,
        event_prefix: [:reactor],
        include_metadata: true

  ## Usage

      defmodule MyReactor do
        use Reactor

        middlewares do
          middleware Reactor.Middleware.TelemetryEventsMiddleware
        end

        # reactor definition...
      end
  """

  @behaviour Reactor.Middleware

  require Logger
  alias Reactor.Middleware.Utils

  @default_event_prefix [:reactor]

  @start_events [:process_start, :run_start, :compensate_start, :undo_start]
  @complete_events [:process_terminate, :run_complete, :compensate_complete, :undo_complete]
  @error_events [:run_error, :compensate_error, :undo_error]
  @retry_events [:run_retry, :compensate_retry, :undo_retry]
  @halt_events [:run_halt]

  @impl true
  def init(context) do
    Utils.safe_execute(
      fn ->
        # Provide default for :enabled
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            reactor_name = Utils.get_reactor_name(context)
            start_time = System.monotonic_time()

            measurements = %{
              system_time: System.system_time(:millisecond),
              monotonic_time: start_time
            }

            metadata = %{
              reactor_name: reactor_name,
              status: :ongoing,
              pid: self(),
              node: node()
            }

            event_name = get_event_prefix() ++ [:start]
            :telemetry.execute(event_name, measurements, metadata)

            updated_context =
              context
              |> Map.put(:telemetry_start_time, start_time)
              |> Map.put(:reactor_name, reactor_name)

            {:ok, updated_context}

          false ->
            {:ok, context}
        end
      end,
      {:ok, context}
    )
  end

  @impl true
  def event(event_type, step, context) do
    Utils.safe_execute(
      fn -> handle_event_if_enabled(event_type, step, context) end,
      :ok
    )
  end

  defp handle_event_if_enabled(event_type, step, context) do
    case Utils.get_config(__MODULE__, :enabled, false) do
      true -> process_event_type(event_type, step, context)
      false -> :ok
    end
  end

  defp process_event_type(event_type, step, context) do
    case event_type do
      type when is_atom(type) -> emit_step_event(type, step, context)
      {type, _args} when is_atom(type) -> emit_step_event(type, step, context)
      _ -> Logger.warning("#{__MODULE__} received an unexpected event_type")
    end

    :ok
  end

  @impl true
  def complete(result, context) do
    Utils.safe_execute(
      fn ->
        # Provide default for :enabled
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            duration = Utils.calculate_duration(context, :telemetry_start_time)
            reactor_name = Utils.get_reactor_name(context)

            measurements = %{
              duration: duration,
              system_time: System.system_time(:millisecond)
            }

            metadata = build_complete_metadata(reactor_name, result, context)

            event_name = get_event_prefix() ++ [:stop]
            :telemetry.execute(event_name, measurements, metadata)

            {:ok, result}

          false ->
            {:ok, result}
        end
      end,
      {:ok, result}
    )
  end

  @impl true
  def error(error, context) do
    Utils.safe_execute(
      fn ->
        # Provide default for :enabled
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            duration = Utils.calculate_duration(context, :telemetry_start_time)
            reactor_name = Utils.get_reactor_name(context)

            measurements = %{
              duration: duration,
              system_time: System.system_time(:millisecond)
            }

            metadata = build_error_metadata(reactor_name, error, context)

            event_name = get_event_prefix() ++ [:stop]
            :telemetry.execute(event_name, measurements, metadata)

            {:error, error}

          false ->
            {:error, error}
        end
      end,
      {:error, error}
    )
  end

  @impl true
  def halt(context) do
    Utils.safe_execute(
      fn ->
        # Provide default for :enabled
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            duration = Utils.calculate_duration(context, :telemetry_start_time)
            reactor_name = Utils.get_reactor_name(context)

            measurements = %{
              duration: duration,
              system_time: System.system_time(:millisecond)
            }

            metadata = %{
              reactor_name: reactor_name,
              halt_reason: Map.get(context, :halt_reason, "unknown"),
              status: :halt,
              pid: self(),
              node: node()
            }

            event_name = get_event_prefix() ++ [:stop]
            :telemetry.execute(event_name, measurements, metadata)

            {:ok, Map.put(context, :telemetry_cleaned, true)}

          false ->
            {:ok, context}
        end
      end,
      {:ok, context}
    )
  end

  def list_all_event_names() do
    [
      @complete_events,
      @error_events,
      @halt_events,
      @retry_events,
      @start_events
    ]
    |> Enum.concat()
    |> Enum.map(&build_step_event_name/1)
  end

  # Private functions

  defp emit_step_event(event_type, step, context) do
    reactor_name = Utils.get_reactor_name(context)

    measurements = build_step_measurements(event_type, step, context)
    metadata = build_step_metadata(event_type, step, reactor_name, context)

    event_name = build_step_event_name(event_type)
    :telemetry.execute(event_name, measurements, metadata)
    :ok
  end

  defp build_step_measurements(event_type, step, context) do
    base_measurements = %{
      system_time: System.system_time(:millisecond)
    }

    event = extract_event_type(event_type)
    add_event_specific_measurements(base_measurements, event, step, context)
  end

  defp extract_event_type(event), do: event

  defp add_event_specific_measurements(base_measurements, event, step, context) do
    cond do
      event in @start_events ->
        Utils.store_step_start_time(step.name)
        Map.put(base_measurements, :step_start_time, System.monotonic_time())

      event in (@complete_events ++ @error_events ++ @retry_events ++ @halt_events) ->
        step_duration = Utils.calculate_step_duration(step, context)
        Map.put(base_measurements, :step_duration, step_duration)

      true ->
        base_measurements
    end
  end

  defp build_step_event_name(event_type) do
    case event_type do
      :process_start ->
        get_event_prefix() ++ [:step, :start]

      :process_terminate ->
        get_event_prefix() ++ [:step, :start]

      :run_start ->
        get_event_prefix() ++ [:step, :run, :start]

      :run_complete ->
        get_event_prefix() ++ [:step, :run, :stop]

      :run_error ->
        get_event_prefix() ++ [:step, :run, :stop]

      :run_retry ->
        get_event_prefix() ++ [:step, :run, :stop]

      :run_halt ->
        get_event_prefix() ++ [:step, :run, :stop]

      :compensate_start ->
        get_event_prefix() ++ [:step, :compensate, :start]

      :compensate_complete ->
        get_event_prefix() ++ [:step, :compensate, :stop]

      :compensate_error ->
        get_event_prefix() ++ [:step, :compensate, :stop]

      :compensate_retry ->
        get_event_prefix() ++ [:step, :compensate, :stop]

      :undo_start ->
        get_event_prefix() ++ [:step, :undo, :start]

      :undo_complete ->
        get_event_prefix() ++ [:step, :undo, :stop]

      :undo_error ->
        get_event_prefix() ++ [:step, :undo, :stop]

      :undo_retry ->
        get_event_prefix() ++ [:step, :undo, :stop]

      _ ->
        Logger.warning("unmateched reactor event: #{inspect(event_type)}")
        get_event_prefix() ++ [:step, :unknown, :stop]
    end
  end

  defp build_step_metadata(event_type, %Reactor.Step{} = step, reactor_name, context) do
    base_metadata = %{
      reactor_name: reactor_name,
      step_name: step.name,
      step_impl: step.impl,
      step_async: step.async?,
      status: determine_step_status(event_type),
      number_of_retries: get_retry_count(event_type, step, context),
      pid: self(),
      node: node()
    }

    case Utils.get_config(__MODULE__, :include_metadata, false) do
      true ->
        additional_metadata = build_additional_metadata(event_type, step, context)
        Map.merge(base_metadata, additional_metadata)

      false ->
        base_metadata
    end
  end

  defp build_additional_metadata(event_type, %Reactor.Step{} = step, _context) do
    case event_type do
      :run_start ->
        %{
          step_argument_count: length(step.arguments),
          step_max_retries: step.max_retries
        }

      :run_complete ->
        %{
          status: "success"
        }

      :run_error ->
        %{
          status: "error",
          error_type: :step_run_error
        }

      :compensate_start ->
        %{
          operation: "compensate",
          status: "compensating"
        }

      :compensate_complete ->
        %{
          operation: "compensate",
          status: "compensated"
        }

      :undo_start ->
        %{
          operation: "undo",
          status: "undoing"
        }

      :undo_complete ->
        %{
          operation: "undo",
          status: "undone"
        }

      _ ->
        %{}
    end
  end

  defp determine_step_status(event_type) do
    cond do
      event_type in @start_events -> :ongoing
      event_type in @complete_events -> :success
      event_type in @error_events -> :error
      event_type in @retry_events -> :retry
      event_type in @halt_events -> :halt
      true -> :unknown
    end
  end

  defp get_retry_count(event_type, step, context) do
    if event_type in @retry_events do
      # Try to get retry count from context or step, defaulting to 0
      Map.get(context, "#{step.name}_retry_count", 0)
    else
      0
    end
  end

  defp build_complete_metadata(reactor_name, result, context) do
    base_metadata = %{
      reactor_name: reactor_name,
      status: :success,
      pid: self(),
      node: node()
    }

    case Utils.get_config(__MODULE__, :include_metadata, false) do
      true ->
        result_metadata = %{
          result_type: Utils.result_type(result),
          result_size: Utils.result_size(result)
        }

        context_metadata = extract_context_metadata(context)

        base_metadata
        |> Map.merge(result_metadata)
        |> Map.merge(context_metadata)

      false ->
        base_metadata
    end
  end

  defp build_error_metadata(reactor_name, error, context) do
    base_metadata = %{
      reactor_name: reactor_name,
      status: :error,
      pid: self(),
      node: node()
    }

    case Utils.get_config(__MODULE__, :include_metadata, false) do
      true ->
        error_metadata = %{
          error_type: Utils.error_type(error),
          error_message: Utils.error_message(error)
        }

        context_metadata = extract_context_metadata(context)

        base_metadata
        |> Map.merge(error_metadata)
        |> Map.merge(context_metadata)

      false ->
        Map.put(base_metadata, :error, inspect(error, limit: 100))
    end
  end

  defp extract_context_metadata(context) do
    context
    |> Map.take([:correlation_id, :user_id, :session_id, :request_id])
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.into(%{})
  end

  defp get_event_prefix do
    Utils.get_config(__MODULE__, :event_prefix, @default_event_prefix)
  end
end
