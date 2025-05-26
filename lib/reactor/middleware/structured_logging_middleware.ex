defmodule Reactor.Middleware.StructuredLoggingMiddleware do
  @moduledoc """
  Structured logging middleware for comprehensive Reactor lifecycle and step execution logging.

  This middleware provides:
  - Reactor lifecycle logging (start, complete, error, halt)
  - Step-level logging with execution context
  - Performance metrics logging
  - Error logging with full context and stack traces

  ## Configuration

      config :area51, Reactor.Middleware.StructuredLoggingMiddleware,
        enabled: true,
        log_level: :info,
        include_arguments: false,
        include_results: false,
        max_argument_size: 1000

  ## Usage

      defmodule MyReactor do
        use Reactor

        middlewares do
          middleware Reactor.Middleware.StructuredLoggingMiddleware
        end

        # reactor definition...
      end
  """

  @behaviour Reactor.Middleware

  require Logger
  alias Reactor.Middleware.Utils

  @impl true
  def init(context) do
    Utils.safe_execute(
      fn ->
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            reactor_name = Utils.get_reactor_name(context)
            start_time = System.monotonic_time()

            log_level = Utils.get_config(__MODULE__, :log_level, :info)

            Logger.log(log_level, "Reactor starting: #{reactor_name}",
              reactor_name: reactor_name,
              start_time: System.system_time(:millisecond),
              context_keys: Map.keys(context),
              pid: inspect(self()),
              node: node()
            )

            updated_context =
              context
              |> Map.put(:logging_start_time, start_time)
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
      fn -> handle_log_event_if_enabled(event_type, step, context) end,
      :ok
    )
  end

  defp handle_log_event_if_enabled(event_type, step, context) do
    case Utils.get_config(__MODULE__, :enabled, false) do
      true -> process_log_event_type(event_type, step, context)
      false -> :ok
    end
  end

  defp process_log_event_type(event_type, step, context) do
    case event_type do
      type when is_atom(type) -> log_step_event(type, step, context)
      {type, _args} when is_atom(type) -> log_step_event(type, step, context)
      _ -> Logger.warning("#{__MODULE__} received an unexpected event_type")
    end

    :ok
  end

  @impl true
  def complete(result, context) do
    Utils.safe_execute(
      fn ->
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            duration = Utils.calculate_duration(context, :logging_start_time)
            reactor_name = Utils.get_reactor_name(context)
            log_level = Utils.get_config(__MODULE__, :log_level, :info)

            result_info = build_result_info(result)

            Logger.log(log_level, "Reactor completed successfully: #{reactor_name}",
              reactor_name: reactor_name,
              duration_ms: duration,
              result_type: result_info.type,
              result_size: result_info.size,
              pid: inspect(self())
            )

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
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            duration = Utils.calculate_duration(context, :logging_start_time)
            reactor_name = Utils.get_reactor_name(context)

            error_info = Utils.build_error_info(error, __MODULE__)

            Logger.error("Reactor execution failed: #{reactor_name}",
              duration_ms: duration,
              error_type: error_info.type,
              error_message: error_info.message,
              error_details: error_info.details,
              stacktrace: error_info.stacktrace,
              pid: inspect(self())
            )

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
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            duration = Utils.calculate_duration(context, :logging_start_time)
            reactor_name = Utils.get_reactor_name(context)

            Logger.warning("Reactor execution halted: #{reactor_name}",
              duration_ms: duration,
              halt_reason: Map.get(context, :halt_reason, "unknown"),
              pid: inspect(self())
            )

            {:ok, Map.put(context, :logging_cleaned, true)}

          false ->
            {:ok, context}
        end
      end,
      {:ok, context}
    )
  end

  # Private functions

  defp log_step_event(event_type, step, context) do
    log_level = get_step_log_level(event_type)
    reactor_name = Utils.get_reactor_name(context)

    base_metadata = [
      reactor_name: reactor_name,
      step_name: step.name,
      step_impl: inspect(step.impl),
      step_async: Map.get(step, :async?, false),
      event_type: event_type,
      pid: inspect(self())
    ]

    metadata =
      case event_type do
        :run_start ->
          step_metadata = build_step_start_metadata(step, context)
          base_metadata ++ step_metadata

        :run_complete ->
          step_metadata = build_step_complete_metadata(step, context)
          base_metadata ++ step_metadata

        :run_error ->
          step_metadata = build_step_error_metadata(step, context)
          base_metadata ++ step_metadata

        :compensate_start ->
          base_metadata ++ [operation: "compensate"]

        :compensate_complete ->
          base_metadata ++ [operation: "compensate", status: "complete"]

        :undo_start ->
          base_metadata ++ [operation: "undo"]

        :undo_complete ->
          base_metadata ++ [operation: "undo", status: "complete"]

        _ ->
          base_metadata
      end

    message = build_step_log_message(event_type, step)
    Logger.log(log_level, message, metadata)
  end

  defp build_step_start_metadata(%Reactor.Step{} = step, _context) do
    base_metadata = [
      step_start_time: System.system_time(:millisecond)
    ]

    argument_metadata =
      case Utils.get_config(__MODULE__, :include_arguments, false) do
        true ->
          arguments = sanitize_arguments(step.arguments)
          [step_arguments: arguments]

        false ->
          [step_argument_count: length(step.arguments)]
      end

    base_metadata ++ argument_metadata
  end

  defp build_step_complete_metadata(_step, _context) do
    [
      step_complete_time: System.system_time(:millisecond),
      step_status: "success"
    ]
  end

  defp build_step_error_metadata(_step, _context) do
    [
      step_complete_time: System.system_time(:millisecond),
      step_status: "error"
    ]
  end

  defp build_step_log_message(event_type, step) do
    message_prefix = get_message_prefix(event_type)
    "#{message_prefix}: #{step.name}"
  end

  defp get_message_prefix(event_type) do
    case get_known_message_prefix(event_type) do
      nil -> get_generic_message_prefix(event_type)
      prefix -> prefix
    end
  end

  defp get_known_message_prefix(event_type) do
    case event_type do
      :run_start -> "Step starting"
      :run_complete -> "Step completed"
      :run_error -> "Step failed"
      :compensate_start -> "Step compensation starting"
      :compensate_complete -> "Step compensation completed"
      :undo_start -> "Step undo starting"
      :undo_complete -> "Step undo completed"
      _ -> nil
    end
  end

  defp get_generic_message_prefix(event_type) when is_atom(event_type),
    do: "Step event #{event_type}"

  defp get_step_log_level(event_type) do
    case event_type do
      :run_error -> :error
      :compensate_start -> :warning
      :compensate_complete -> :warning
      :undo_start -> :warning
      :undo_complete -> :warning
      _ -> Utils.get_config(__MODULE__, :log_level, :info)
    end
  end

  defp build_result_info(result) do
    %{
      type: Utils.result_type(result),
      size: Utils.result_size(result)
    }
  end

  defp sanitize_arguments(arguments) when is_list(arguments) do
    max_size = Utils.get_config(__MODULE__, :max_argument_size, 1000)

    arguments
    |> Enum.map(fn %Reactor.Argument{name: name, source: source} ->
      sanitized_source = sanitize_value(source, max_size)
      {name, sanitized_source}
    end)
    |> Enum.into(%{})
  end

  defp sanitize_arguments(arguments), do: inspect(arguments, limit: 100)

  defp sanitize_value(value, max_size) do
    inspected = inspect(value, limit: max_size)

    if String.length(inspected) > max_size do
      String.slice(inspected, 0, max_size) <> "...[truncated]"
    else
      inspected
    end
  end
end
