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

            # Check if external OpenTelemetry context is provided
            {ctx, span_ctx} = create_reactor_span(reactor_name, context)

            updated_context =
              context
              |> Map.put(:otel_ctx, ctx)
              |> Map.put(:otel_span_ctx, span_ctx)
              |> Map.put(:otel_start_time, start_time)
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
  def complete(result, context) do
    Utils.safe_execute(
      fn ->
        case context do
          %{otel_span_ctx: span_ctx, otel_ctx: ctx} ->
            OpenTelemetry.Ctx.attach(ctx)
            OpenTelemetry.Tracer.set_current_span(span_ctx)
            duration = Utils.calculate_duration(context, :otel_start_time)

            Tracer.set_attributes([
              {:"reactor.status", "success"},
              {:"reactor.result_type", Utils.result_type(result)},
              {:"reactor.duration_ms", duration}
            ])

            Tracer.set_status(:ok, "success")
            OpenTelemetry.Span.end_span(span_ctx)

            {:ok, result}

          _ ->
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
        case context do
          %{otel_span_ctx: span_ctx, otel_ctx: ctx} ->
            OpenTelemetry.Ctx.attach(ctx)
            OpenTelemetry.Tracer.set_current_span(span_ctx)
            duration = Utils.calculate_duration(context, :otel_start_time)

            error_info = Utils.build_error_info(error, __MODULE__)

            Tracer.set_attributes([
              {:"reactor.status", "error"},
              {:"reactor.error_type", error_info.type},
              {:"reactor.error_message", error_info.message},
              {:"reactor.duration_ms", duration}
            ])

            Tracer.set_status(:error, error_info.message)
            OpenTelemetry.Span.end_span(span_ctx)

            {:error, error}

          _ ->
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
        case context do
          %{otel_span_ctx: span_ctx, otel_ctx: ctx} ->
            OpenTelemetry.Ctx.attach(ctx)
            OpenTelemetry.Tracer.set_current_span(span_ctx)
            duration = Utils.calculate_duration(context, :otel_start_time)

            Tracer.set_attributes([
              {:"reactor.status", "halted"},
              {:"reactor.duration_ms", duration}
            ])

            Tracer.set_status(:ok, "halted")
            OpenTelemetry.Span.end_span(span_ctx)

            # clean up any non-reactor-managed resources or modify the context
            # for later re-use by a future init/1 callback.
            updated_context =
              context
              |> Map.delete(:otel_ctx)
              |> Map.delete(:otel_span_ctx)
              |> Map.delete(:otel_start_time)

            {:ok, updated_context}

          _ ->
            updated_context =
              context
              |> Map.delete(:otel_ctx)
              |> Map.delete(:otel_span_ctx)
              |> Map.delete(:otel_start_time)

            {:ok, updated_context}
        end
      end,
      {:ok, context}
    )
  end

  @impl true
  def event(event_type, step, context) do
    Utils.safe_execute(
      fn ->
        case Utils.get_config(__MODULE__, :enabled, false) do
          true -> process_otel_event_type(event_type, step, context)
          false -> :ok
        end
      end,
      :ok
    )
  end

  # Private functions
  defp create_reactor_span(reactor_name, context) do
    case context do
      %{otel_ctx: external_ctx, otel_span_ctx: external_span} ->
        # Use external context as parent
        OpenTelemetry.Ctx.attach(external_ctx)
        OpenTelemetry.Tracer.set_current_span(external_span)

        span_name = "reactor.#{reactor_name}.run"
        span_attributes = build_reactor_attributes(reactor_name, context)
        child_span = Tracer.start_span(span_name, %{attributes: span_attributes})
        current_ctx = OpenTelemetry.Ctx.get_current()

        {current_ctx, child_span}

      _ ->
        # Create root span
        span_name = "reactor.#{reactor_name}.run"
        span_attributes = build_reactor_attributes(reactor_name, context)
        span_ctx = Tracer.start_span(span_name, %{attributes: span_attributes})
        ctx = OpenTelemetry.Ctx.get_current()

        {ctx, span_ctx}
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

  defp handle_step_event(event_type, %Reactor.Step{} = step, context, args) do
    cond do
      event_type in @start_events -> handle_start_event(event_type, step, context)
      event_type in @end_events -> handle_end_event(event_type, step, context)
      event_type in @error_events -> handle_error_event(event_type, step, context, args)
    end
  end

  defp map_to_event_kind(event_type) do
    case event_type do
      :process_start -> :process
      :process_terminate -> :process
      # run setps
      :run_start -> :run
      :run_complete -> :run
      :run_retry -> :run
      :run_halt -> :run
      # compensate setps
      :compensate_start -> :compensate
      :compensate_complete -> :compensate
      :compensate_retry -> :compensate
      # undo setps
      :undo_start -> :undo
      :undo_complete -> :undo
      :undo_retry -> :undo
    end
  end

  defp handle_start_event(event_type, step, context) do
    event_kind = map_to_event_kind(event_type)

    start_time = System.monotonic_time()
    Process.put({__MODULE__, :step_start_time, step.name, event_kind}, start_time)

    ctx = OpenTelemetry.Ctx.get_current()
    Process.put({__MODULE__, :step_ctx, step.name, event_kind}, ctx)

    step_span = create_span_for_event(event_type, step, context)
    Process.put({__MODULE__, :step_span_ctx, step.name, event_kind}, step_span)
  end

  defp handle_end_event(event_type, step, context) do
    complete_span_for_event(event_type, step, context, :success, nil)
  end

  defp handle_error_event(event_type, step, context, args) do
    error = extract_error_from_args(args)
    complete_span_for_event(event_type, step, context, :error, error)
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
    span_name =
      case event_type do
        :run_start -> "step.#{step.name}.run"
        :compensate_start -> "step.#{step.name}.compensate"
        :undo_start -> "step.#{step.name}.undo"
        :process_start -> "step.#{step.name}.process"
        event_type -> "step.#{step.name}." <> to_string(event_type)
      end

    span_attributes =
      build_step_attributes(step, context)

    # Set parent context before creating child span for proper hierarchy
    case context do
      %{otel_span_ctx: parent, otel_ctx: parent_ctx} ->
        OpenTelemetry.Ctx.attach(parent_ctx)
        OpenTelemetry.Tracer.set_current_span(parent)

      _ ->
        :ok
    end

    Tracer.start_span(span_name, %{attributes: span_attributes})
  end

  # Complete appropriate span based on event type
  defp complete_span_for_event(event_type, %Reactor.Step{} = step, _context, status, error) do
    event_kind = map_to_event_kind(event_type)

    start_time = Process.delete({__MODULE__, :step_start_time, step.name, event_kind})

    end_time = System.monotonic_time()
    step_duration = end_time - start_time

    ctx = Process.delete({__MODULE__, :step_ctx, step.name, event_kind})
    OpenTelemetry.Ctx.attach(ctx)

    span_ctx = Process.delete({__MODULE__, :step_span_ctx, step.name, event_kind})

    OpenTelemetry.Tracer.set_current_span(span_ctx)

    base_attributes = [
      {:"step.event_type", to_string(event_type)},
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

    OpenTelemetry.Span.end_span(span_ctx)
  end

  defp build_reactor_attributes(reactor_name, context) do
    base_attrs = [
      {:"reactor.name", reactor_name},
      {:"reactor.start_time", System.system_time(:millisecond)}
    ]

    config_attrs = Utils.get_config(__MODULE__, :span_attributes, [])
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
      case Utils.get_config(__MODULE__, :include_arguments, false) do
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
end
