defmodule Area51.Web.PromEx.Plugins.ReactorPlugin do
  @moduledoc """
  PromEx plugin for collecting metrics from Reactor executions.

  This plugin captures metrics from reactor telemetry events emitted by
  the TelemetryEventsMiddleware, providing comprehensive monitoring
  of reactor and step executions.

  ## Metrics Collected

  ### Reactor-level metrics:
  - reactor_executions_total - Counter of reactor executions by status
  - reactor_execution_duration_seconds - Histogram of reactor execution durations

  ### Step-level metrics:
  - reactor_step_executions_total - Counter of step executions by type and status
  - reactor_step_execution_duration_seconds - Histogram of step execution durations
  - reactor_step_retries_total - Counter of step retries
  - reactor_step_errors_total - Counter of step errors by type

  All metrics include relevant labels like reactor_name, step_name, status, etc.
  """
  use PromEx.Plugin

  import Telemetry.Metrics

  @impl true
  def event_metrics(_opts) do
    Event.build(
      :reactor_event_metrics,
      [
        # Reactor-level metrics
        counter("reactor.count",
          event_name: [:reactor, :stop],
          description: "Total number of reactor executions",
          tags: [:reactor_name, :status, :node],
          tag_values: &reactor_tag_values/1
        ),
        distribution("reactor.stop.duration",
          event_name: [:reactor, :stop],
          description: "Duration of reactor executions",
          measurement: :duration,
          unit: {:native, :second},
          reporter_options: [
            buckets: exponential!(1, 2, 12)
          ],
          tags: [:reactor_name, :status, :node],
          tag_values: &reactor_tag_values/1
        ),

        # Step-level metrics
        counter("reactor.step.run.count",
          event_name: [:reactor, :step, :run, :stop],
          description: "Total number of step run executions",
          tags: [:reactor_name, :step_name, :step_impl, :status, :number_of_retries, :async],
          tag_values: &step_tag_values/1
        ),
        counter("reactor.step.compensate.count",
          event_name: [:reactor, :step, :compensate, :stop],
          description: "Total number of step compensations",
          tags: [:reactor_name, :step_name, :step_impl, :status, :number_of_retries, :async],
          tag_values: &step_tag_values/1
        ),
        counter("reactor.step.undo.count",
          event_name: [:reactor, :step, :undo, :stop],
          description: "Total number of step undos",
          tags: [:reactor_name, :step_name, :step_impl, :status, :number_of_retries, :async],
          tag_values: &step_tag_values/1
        ),
        distribution("reactor.step.run.duration",
          event_name: [:reactor, :step, :run, :stop],
          description: "Duration of step run executions",
          measurement: :step_duration,
          unit: {:native, :second},
          reporter_options: [
            buckets: exponential!(1, 2, 12)
          ],
          tags: [:reactor_name, :step_name, :step_impl, :status, :number_of_retries, :async],
          tag_values: &step_tag_values/1
        ),
        distribution("reactor.step.compensate.duration",
          event_name: [:reactor, :step, :compensate, :stop],
          description: "Duration of step compensations",
          measurement: :step_duration,
          unit: {:native, :second},
          reporter_options: [
            buckets: exponential!(1, 2, 12)
          ],
          tags: [:reactor_name, :step_name, :step_impl, :status, :number_of_retries, :async],
          tag_values: &step_tag_values/1
        ),
        distribution("reactor.step.undo.duration",
          event_name: [:reactor, :step, :undo, :stop],
          description: "Duration of step undos",
          measurement: :step_duration,
          unit: {:native, :second},
          reporter_options: [
            buckets: exponential!(1, 2, 12)
          ],
          tags: [:reactor_name, :step_name, :step_impl, :status, :number_of_retries, :async],
          tag_values: &step_tag_values/1
        )
      ]
    )
  end

  # Helper functions for tag values

  defp reactor_tag_values(metadata) do
    %{
      reactor_name: Map.get(metadata, :reactor_name, "unknown"),
      status: Map.get(metadata, :status, "unknown"),
      node: Map.get(metadata, :node, node())
    }
  end

  defp step_tag_values(metadata) do
    %{
      reactor_name: Map.get(metadata, :reactor_name, "unknown"),
      step_name: Map.get(metadata, :step_name, "unknown"),
      step_impl: format_step_impl(Map.get(metadata, :step_impl)),
      status: Map.get(metadata, :status, "unknown"),
      number_of_retries: Map.get(metadata, :number_of_retries, 0),
      async: Map.get(metadata, :step_async, false)
    }
  end

  defp format_step_impl(nil), do: "unknown"
  defp format_step_impl(module) when is_atom(module), do: inspect(module)
  defp format_step_impl(other), do: inspect(other)
end
