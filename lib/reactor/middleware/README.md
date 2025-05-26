# Reactor Middleware Instrumentation System

This directory contains a comprehensive middleware system for automatic instrumentation of Reactor workflows. The system provides OpenTelemetry tracing, structured logging, and Elixir telemetry events with minimal configuration and zero impact on business logic.

## Overview

The middleware system consists of three main components:

- **OpenTelemetryMiddleware**: Automatic span creation and context propagation
- **StructuredLoggingMiddleware**: Comprehensive lifecycle and step logging
- **TelemetryEventsMiddleware**: Elixir telemetry events for metrics collection

## Quick Start

### 1. Basic Usage

Add middleware to your reactor using the `middlewares` DSL:

```elixir
defmodule MyApp.MyReactor do
  use Reactor

  # Explicit opt-in to instrumentation
  middlewares do
    middleware Reactor.Middleware.OpenTelemetryMiddleware
    middleware Reactor.Middleware.StructuredLoggingMiddleware  
    middleware Reactor.Middleware.TelemetryEventsMiddleware
  end

  input(:data)

  step :process_data, ProcessDataStep do
    argument(:data, input(:data))
  end

  return(:process_data)
end
```

### 2. Configuration

Configure middleware in your application config:

```elixir
# config/config.exs
config :area51, Reactor.Middleware.OpenTelemetryMiddleware,
  enabled: true,
  span_attributes: [
    service_name: "my_app",
    service_version: "1.0.0"
  ],
  include_arguments: false,  # For security
  include_results: false     # For security

config :area51, Reactor.Middleware.StructuredLoggingMiddleware,
  enabled: true,
  log_level: :info,
  include_arguments: false,
  include_results: false,
  max_argument_size: 1000

config :area51, Reactor.Middleware.TelemetryEventsMiddleware,
  enabled: true,
  event_prefix: [:my_app, :reactor],
  include_metadata: true
```

### 3. Environment-Specific Configuration

```elixir
# config/dev.exs
config :area51, Reactor.Middleware.StructuredLoggingMiddleware,
  log_level: :debug,
  include_arguments: true,
  include_results: true

# config/test.exs
config :area51, Reactor.Middleware.OpenTelemetryMiddleware,
  enabled: false

config :area51, Reactor.Middleware.StructuredLoggingMiddleware,
  enabled: false

# config/prod.exs
config :area51, Reactor.Middleware.StructuredLoggingMiddleware,
  include_arguments: false,
  include_results: false,
  max_argument_size: 500
```

## Features

### OpenTelemetry Integration

- **Automatic span creation** for reactor runs and individual steps
- **Hierarchical tracing** with proper parent-child relationships
- **Context propagation** across async steps
- **Error attribution** with detailed span attributes
- **Custom attributes** from reactor context

Example span hierarchy:
```
reactor.run (reactor_name: "MyReactor")
├── reactor.step.run (step_name: "process_data")
│   └── reactor.step.complete
└── reactor.complete
```

### Structured Logging

- **Reactor lifecycle events**: start, complete, error, halt
- **Step-level events**: run_start, run_complete, run_error, compensate, undo
- **Performance metrics**: execution duration, step timing
- **Error details**: stack traces, error context
- **Configurable privacy**: control argument/result logging

Example log output:
```
[info] Reactor starting reactor_name=MyReactor start_time=1640995200000 pid=#PID<0.123.0>
[info] Step starting: process_data reactor_name=MyReactor step_name=process_data step_async=false
[info] Step completed: process_data reactor_name=MyReactor step_name=process_data step_status=success
[info] Reactor completed successfully reactor_name=MyReactor duration_ms=150 result_type=map
```

### Telemetry Events

Emitted events for metrics collection:

**Reactor Events:**
- `[:reactor, :start]` - Reactor execution starts
- `[:reactor, :stop]` - Reactor execution completes
- `[:reactor, :error]` - Reactor execution fails
- `[:reactor, :halt]` - Reactor execution halted

**Step Events:**
- `[:reactor, :step, :run_start]` - Step execution starts
- `[:reactor, :step, :run_complete]` - Step execution completes
- `[:reactor, :step, :run_error]` - Step execution fails

## Advanced Usage

### Selective Middleware

You can enable only specific middleware:

```elixir
defmodule MyApp.LightweightReactor do
  use Reactor

  # Only enable logging, no tracing overhead
  middlewares do
    middleware Reactor.Middleware.StructuredLoggingMiddleware
  end

  # reactor definition...
end
```

### Runtime Configuration

Control instrumentation via environment variables:

```bash
# Disable all instrumentation
export INSTRUMENTATION_ENABLED=false

# Set instrumentation level
export INSTRUMENTATION_LEVEL=debug  # minimal, standard, debug, disabled

# Control specific features
export INSTRUMENTATION_LOG_LEVEL=warning
export INSTRUMENTATION_INCLUDE_ARGS=false
```

### Custom Event Handlers

Set up custom telemetry handlers:

```elixir
defmodule MyApp.TelemetryHandler do
  def setup do
    :telemetry.attach_many(
      "my-app-reactor-handler",
      [
        [:reactor, :start],
        [:reactor, :stop],
        [:reactor, :error]
      ],
      &handle_event/4,
      nil
    )
  end

  defp handle_event([:reactor, :stop], measurements, metadata, _config) do
    # Custom metrics collection
    MyApp.Metrics.record_reactor_duration(
      metadata.reactor_name,
      measurements.duration
    )
  end

  defp handle_event([:reactor, :error], _measurements, metadata, _config) do
    # Custom error tracking
    MyApp.ErrorTracker.record_reactor_error(
      metadata.reactor_name,
      metadata.error
    )
  end

  defp handle_event(_, _, _, _), do: :ok
end
```

## Performance Considerations

### Minimal Overhead When Disabled

When middleware is disabled, operations are no-ops with minimal performance impact:

```elixir
# Disabled middleware
Application.put_env(:area51, Reactor.Middleware.OpenTelemetryMiddleware, enabled: false)

# Results in fast no-op operations
{:ok, context} = OpenTelemetryMiddleware.init(context)  # ~1μs
:ok = OpenTelemetryMiddleware.event(:run_start, step, context)  # ~1μs
```

### Async-Safe Context Propagation

The system safely propagates OpenTelemetry context across async step boundaries:

```elixir
# Automatic context propagation for async steps
def get_process_context do
  %{
    otel_context: OpenTelemetry.Ctx.get_current(),
    span_context: OpenTelemetry.Tracer.current_span_ctx()
  }
end

def set_process_context(context) do
  OpenTelemetry.Ctx.attach(context.otel_context)
  OpenTelemetry.Tracer.set_current_span(context.span_context)
  :ok
end
```

### Memory Management

The middleware system includes proper resource cleanup:

- Automatic span cleanup on reactor completion/error/halt
- Context cleanup for async steps
- Configurable argument size limits to prevent memory issues

## Error Handling

The middleware system is designed to never interfere with reactor execution:

```elixir
# All middleware operations are wrapped in safe_execute
defp safe_execute(operation, fallback \\ :ok) do
  try do
    operation.()
  rescue
    error ->
      Logger.warning("Middleware error: #{inspect(error)}")
      fallback  # Never fail the reactor
  end
end
```

### Graceful Degradation

- Instrumentation failures don't affect business logic
- Fallback to basic logging when OpenTelemetry unavailable
- Configuration validation with sensible defaults

## Integration with Existing Telemetry

The middleware integrates with your existing telemetry setup in `Area51.Web.Telemetry`:

```elixir
def metrics do
  [
    # Existing metrics...
    
    # Reactor metrics added automatically
    summary("reactor.duration",
      tags: [:reactor_name, :status],
      unit: {:native, :millisecond}
    ),
    
    summary("reactor.step.duration",
      tags: [:reactor_name, :step_name, :status],
      unit: {:native, :millisecond}
    ),
    
    counter("reactor.errors",
      tags: [:reactor_name, :step_name, :error_type]
    )
  ]
end
```

## Testing

The middleware system includes comprehensive tests:

```bash
# Run middleware tests
mix test test/reactor/middleware/

# Run specific middleware tests
mix test test/reactor/middleware/opentelemetry_middleware_test.exs
mix test test/reactor/middleware/telemetry_events_middleware_test.exs
mix test test/reactor/middleware/integration_test.exs
```

### Test Configuration

For testing, disable instrumentation to avoid overhead:

```elixir
# test/test_helper.exs
Application.put_env(:area51, Reactor.Middleware.OpenTelemetryMiddleware, enabled: false)
Application.put_env(:area51, Reactor.Middleware.StructuredLoggingMiddleware, enabled: false)
Application.put_env(:area51, Reactor.Middleware.TelemetryEventsMiddleware, enabled: false)
```

## Examples

Below is an example demonstrating how to define steps, a reactor, and run it with instrumentation.
Make sure the necessary middleware modules (e.g., `Reactor.Middleware.OpenTelemetryMiddleware`)
are available and configured as shown in the "Quick Start" section.

```elixir
defmodule MyApp.InstrumentedReactorExample do
  # Example step implementations
  defmodule ProcessDataStep do
    use Reactor.Step

    @impl true
    def run(arguments, _context, _options) do
      data = arguments.data
      # Simulate processing
      Process.sleep(10)
      processed_data = %{
        original: data,
        processed_at: DateTime.utc_now(),
        size: byte_size(inspect(data))
      }
      {:ok, processed_data}
    end
  end

  defmodule ValidateResultStep do
    use Reactor.Step

    @impl true
    def run(arguments, _context, _options) do
      result = arguments.result
      if Map.has_key?(result, :original) do
        {:ok, Map.put(result, :validated, true)}
      else
        {:error, :invalid_result}
      end
    end
  end

  # Reactor definition
  defmodule BasicInstrumentedReactor do
    use Reactor

    # Ensure these middleware are defined or aliased appropriately
    # e.g., alias Reactor.Middleware.{OpenTelemetryMiddleware, StructuredLoggingMiddleware, TelemetryEventsMiddleware}
    middlewares do
      middleware(Reactor.Middleware.OpenTelemetryMiddleware)
      middleware(Reactor.Middleware.StructuredLoggingMiddleware)
      middleware(Reactor.Middleware.TelemetryEventsMiddleware)
    end

    input(:data)

    step :process_data, ProcessDataStep do
      argument(:data, input(:data))
    end

    step :validate_result, ValidateResultStep do
      argument(:result, result(:process_data))
    end

    return(:validate_result)
  end

  # Running the reactor
  def run_basic_example do
    IO.puts("Running BasicInstrumentedReactor...")
    result = Reactor.run(BasicInstrumentedReactor, %{data: "test data"})
    IO.inspect(result, label: "Result of BasicInstrumentedReactor")
    result # Return the result for potential further use or testing
  end
end

# To run this example (assuming the module is compiled and available):
# MyApp.InstrumentedReactorExample.run_basic_example()
```
## Troubleshooting

### Common Issues

1. **No telemetry events received**
   - Check that middleware is enabled in configuration
   - Verify telemetry handlers are attached
   - Ensure reactor includes middleware in `middlewares` block

2. **OpenTelemetry spans not appearing**
   - Verify OpenTelemetry is properly configured
   - Check that OpenTelemetry middleware is enabled
   - Ensure OpenTelemetry exporter is configured

3. **Performance issues**
   - Disable argument/result logging in production
   - Set appropriate log levels
   - Consider disabling middleware for high-frequency reactors

4. **Memory usage**
   - Configure `max_argument_size` to limit logging
   - Disable `include_arguments` and `include_results` in production
   - Monitor span cleanup in long-running reactors

### Debug Mode

Enable debug mode for detailed instrumentation logging:

```elixir
config :area51, Reactor.Middleware.StructuredLoggingMiddleware,
  log_level: :debug,
  include_arguments: true,
  include_results: true
```

Or via environment variable:
```bash
export INSTRUMENTATION_LEVEL=debug
```

## Contributing

When adding new middleware or modifying existing ones:

1. Follow the `Reactor.Middleware` behaviour
2. Include comprehensive error handling with `safe_execute`
3. Add configuration validation
4. Write tests for all middleware callbacks
5. Update documentation and examples
6. Consider performance impact and memory usage

## Architecture

For detailed architecture information, see `REACTOR_MIDDLEWARE_INSTRUMENTATION_DESIGN.md`.