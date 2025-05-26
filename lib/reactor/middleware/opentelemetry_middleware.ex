defmodule Reactor.Middleware.OpenTelemetryMiddleware do
  @moduledoc """
  OpenTelemetry middleware for automatic instrumentation of Reactor workflows.

  This middleware provides:
  - Automatic span creation for Reactor runs and individual steps
  - Proper parent-child span relationships
  - Context propagation across async steps
  - Span attributes for step names, arguments, results, and errors

  ## Configuration

      config :area51, Reactor.Middleware.OpenTelemetryMiddleware,
        enabled: true,
        span_attributes: [
          service_name: "area51.llm",
          service_version: "0.1.0"
        ],
        include_arguments: false,
        include_results: false

  ## Usage

      defmodule MyReactor do
        use Reactor

        middlewares do
          middleware Reactor.Middleware.OpenTelemetryMiddleware
        end

        # reactor definition...
      end
  """

  @behaviour Reactor.Middleware

  require OpenTelemetry.Tracer
  alias OpenTelemetry.Tracer

  require Logger
  alias Reactor.Middleware.Utils

  @start_events [:process_start, :run_start, :compensate_start, :undo_start]
  @end_events [:process_terminate, :run_complete, :run_halt, :compensate_complete, :undo_complete]
  @error_events [:run_retry, :compensate_retry, :undo_retry]

  @impl true
  def init(context) do
    Utils.safe_execute(
      fn ->
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            reactor_name = Utils.get_reactor_name(context)
            start_time = System.monotonic_time()

            span_name = "reactor.run"
            span_attributes = build_reactor_attributes(reactor_name, context)

            Tracer.with_span span_name, %{attributes: span_attributes} do
              span_ctx = Tracer.current_span_ctx()

              updated_context =
                context
                |> Map.put(:otel_span_ctx, span_ctx)
                |> Map.put(:otel_start_time, start_time)
                |> Map.put(:reactor_name, reactor_name)

              {:ok, updated_context}
            end

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
      fn -> handle_otel_event_if_enabled(event_type, step, context) end,
      :ok
    )
  end

  defp handle_otel_event_if_enabled(event_type, step, context) do
    case Utils.get_config(__MODULE__, :enabled, false) do
      true -> process_otel_event_type(event_type, step, context)
      false -> :ok
    end
  end

  defp process_otel_event_type(event_type, step, context) do
    case event_type do
      type when is_atom(type) -> handle_step_event(type, step, context, nil)
      {type, args} when is_atom(type) -> handle_step_event(type, step, context, args)
      _ -> Logger.warning("#{__MODULE__} received an unexpected event_type")
    end

    :ok
  end

  @impl true
  def get_process_context do
    Utils.safe_execute(
      fn ->
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            ctx = OpenTelemetry.Ctx.get_current()
            span_ctx = Tracer.current_span_ctx()

            %{
              otel_context: ctx,
              span_context: span_ctx,
              process_info: %{
                pid: self(),
                node: node()
              }
            }

          false ->
            nil
        end
      end,
      nil
    )
  end

  @impl true
  def set_process_context(nil), do: :ok

  def set_process_context(context) do
    Utils.safe_execute(
      fn ->
        case context do
          %{otel_context: ctx, span_context: span_ctx} ->
            OpenTelemetry.Ctx.attach(ctx)
            Tracer.set_current_span(span_ctx)
            :ok

          _ ->
            :ok
        end
      end,
      :ok
    )
  end

  @impl true
  def complete(result, context) do
    Utils.safe_execute(
      fn ->
        case Utils.get_config(__MODULE__, :enabled, false) do
          true ->
            duration = Utils.calculate_duration(context, :otel_start_time)

            Tracer.set_attributes([
              {:"reactor.status", "success"},
              {:"reactor.result_type", Utils.result_type(result)},
              {:"reactor.duration_ms", duration}
            ])

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
            duration = Utils.calculate_duration(context, :otel_start_time)

            error_info = Utils.build_error_info(error, __MODULE__)

            Tracer.set_attributes([
              {:"reactor.status", "error"},
              {:"reactor.error_type", error_info.type},
              {:"reactor.error_message", error_info.message},
              {:"reactor.duration_ms", duration}
            ])

            Tracer.set_status(:error, error_info.message)
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
            duration = Utils.calculate_duration(context, :otel_start_time)

            Tracer.set_attributes([
              {:"reactor.status", "halted"},
              {:"reactor.duration_ms", duration}
            ])

            cleanup_spans()
            {:ok, Map.put(context, :otel_cleaned, true)}

          false ->
            {:ok, context}
        end
      end,
      {:ok, context}
    )
  end

  # Private functions

  defp handle_step_event(event_type, %Reactor.Step{} = step, context, args) do
    cond do
      event_type in @start_events -> handle_start_event(event_type, step, context)
      event_type in @end_events -> handle_end_event(event_type, step, context)
      event_type in @error_events -> handle_error_event(event_type, step, context, args)
      true -> handle_legacy_event(event_type, step, context, args)
    end
  end

  defp handle_start_event(event_type, step, context) do
    Utils.store_step_start_time(step.name)
    create_span_for_event(event_type, step, context)
  end

  defp handle_end_event(event_type, step, context) do
    complete_span_for_event(event_type, step, context, :success, nil)
  end

  defp handle_error_event(event_type, step, context, args) do
    error = extract_error_from_args(args)
    complete_span_for_event(event_type, step, context, :error, error)
  end

  defp handle_legacy_event(event_type, step, context, args) do
    case event_type do
      :run_start ->
        Utils.store_step_start_time(step.name)
        create_step_span(step, context)

      :run_complete ->
        complete_step_span(step, context, :success, nil)

      :run_error ->
        error = extract_error_from_args(args)
        complete_step_span(step, context, :error, error)

      :compensate_start ->
        Utils.store_step_start_time(step.name)
        create_compensation_span(step, context)

      :compensate_complete ->
        complete_compensation_span(step, context)

      :undo_start ->
        Utils.store_step_start_time(step.name)
        create_undo_span(step, context)

      :undo_complete ->
        complete_undo_span(step, context)

      _ ->
        :ok
    end
  end

  # Extract error information from event arguments
  defp extract_error_from_args(args) do
    case args do
      %{error: error} -> error
      error when error != nil -> error
      _ -> nil
    end
  end

  # Create appropriate span based on event type
  defp create_span_for_event(event_type, step, context) do
    case event_type do
      :run_start -> create_step_span(step, context)
      :compensate_start -> create_compensation_span(step, context)
      :undo_start -> create_undo_span(step, context)
      :process_start -> create_process_span(step, context)
      _ -> :ok
    end
  end

  # Complete appropriate span based on event type
  defp complete_span_for_event(event_type, step, context, status, error) do
    case event_type do
      event when event in [:run_complete, :run_halt] ->
        complete_step_span(step, context, status, error)

      event when event in [:compensate_complete] ->
        complete_compensation_span(step, context)

      event when event in [:undo_complete] ->
        complete_undo_span(step, context)

      event when event in [:process_terminate] ->
        complete_process_span(step, context, status)

      _ ->
        :ok
    end
  end

  defp create_step_span(%Reactor.Step{} = step, context) do
    span_name = "reactor.step.run"
    span_attributes = build_step_attributes(step, context)

    Tracer.start_span(span_name, %{attributes: span_attributes})
  end

  defp complete_step_span(%Reactor.Step{} = step, context, status, error) do
    step_duration = Utils.calculate_step_duration(step, context)

    base_attributes = [
      {:"step.status", to_string(status)},
      {:"step.duration_ms", step_duration}
    ]

    attributes =
      case {status, error} do
        {:error, nil} ->
          base_attributes

        {:error, error} ->
          error_info = Utils.build_error_info(error, __MODULE__)

          base_attributes ++
            [
              {:"step.error_type", error_info.type},
              {:"step.error_message", error_info.message}
            ]

        _ ->
          base_attributes
      end

    case status do
      :error ->
        Tracer.set_attributes(attributes)

        error_message =
          case error do
            nil -> "Step execution failed"
            _ -> Utils.error_message(error)
          end

        Tracer.set_status(:error, error_message)

      :success ->
        Tracer.set_attributes(attributes)
    end

    Tracer.end_span()
  end

  defp create_compensation_span(%Reactor.Step{} = step, _context) do
    span_name = "reactor.step.compensate"
    span_attributes = [{:"step.name", step.name}, {:"step.operation", "compensate"}]

    Tracer.start_span(span_name, %{attributes: span_attributes})
  end

  defp complete_compensation_span(%Reactor.Step{} = step, context) do
    step_duration = Utils.calculate_step_duration(step, context)

    Tracer.set_attributes([
      {:"step.compensation.status", "complete"},
      {:"step.duration_ms", step_duration}
    ])

    Tracer.end_span()
  end

  defp create_undo_span(%Reactor.Step{} = step, _context) do
    span_name = "reactor.step.undo"
    span_attributes = [{:"step.name", step.name}, {:"step.operation", "undo"}]

    Tracer.start_span(span_name, %{attributes: span_attributes})
  end

  defp complete_undo_span(%Reactor.Step{} = step, context) do
    step_duration = Utils.calculate_step_duration(step, context)

    Tracer.set_attributes([
      {:"step.undo.status", "complete"},
      {:"step.duration_ms", step_duration}
    ])

    Tracer.end_span()
  end

  defp create_process_span(%Reactor.Step{} = step, _context) do
    span_name = "reactor.process.start"
    span_attributes = [{:"step.name", step.name}, {:"step.operation", "process"}]

    Tracer.start_span(span_name, %{attributes: span_attributes})
  end

  defp complete_process_span(%Reactor.Step{} = step, context, status) do
    step_duration = Utils.calculate_step_duration(step, context)

    Tracer.set_attributes([
      {:"process.status", to_string(status)},
      {:"step.duration_ms", step_duration}
    ])

    Tracer.end_span()
  end

  defp build_reactor_attributes(reactor_name, context) do
    base_attrs = [
      {:"reactor.name", reactor_name},
      {:"reactor.start_time", System.system_time(:millisecond)}
    ]

    config_attrs = get_config(:span_attributes, [])
    context_attrs = extract_context_attributes(context)

    base_attrs ++ config_attrs ++ context_attrs
  end

  defp build_step_attributes(%Reactor.Step{} = step, context) do
    base_attrs = [
      {:"step.name", step.name},
      {:"step.impl", inspect(step.impl)},
      {:"step.async", step.async?},
      {:"step.argument_count", length(step.arguments)}
    ]

    argument_attrs =
      case get_config(:include_arguments, false) do
        true -> [{:"step.arguments", format_step_arguments(step.arguments)}]
        false -> []
      end

    reactor_attrs = [
      {:"reactor.name", Map.get(context, :reactor_name, "unknown")}
    ]

    base_attrs ++ argument_attrs ++ reactor_attrs
  end

  defp format_step_arguments(arguments) when is_list(arguments) do
    Enum.map_join(arguments, ", ", fn %Reactor.Argument{name: name, source: source} ->
      "#{name}: #{inspect(source, limit: 50)}"
    end)
  end

  defp format_step_arguments(arguments), do: inspect(arguments, limit: 100)

  defp extract_context_attributes(context) do
    context
    |> Map.take([:correlation_id, :user_id, :session_id])
    |> Enum.map(fn {key, value} -> {:"context.#{key}", value} end)
  end

  defp cleanup_spans do
    case Tracer.current_span_ctx() do
      :undefined -> :ok
      _span_ctx -> Tracer.end_span()
    end
  end

  defp get_config(key, default) do
    :area51
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(key, default)
  end
end
