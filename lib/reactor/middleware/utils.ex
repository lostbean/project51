defmodule Reactor.Middleware.Utils do
  @moduledoc """
  Shared utilities for Reactor middleware implementations.

  This module provides common functionality used across multiple middleware
  implementations, reducing code duplication and providing consistent behavior.

  ## Functions

  - `get_reactor_name/1` - Extract reactor name from context
  - `safe_execute/3` - Execute operations with error handling
  - `calculate_duration/2` - Calculate duration from context start time
  - `get_config/3` - Get configuration with fallback
  - `result_type/1` - Determine the type of a result value
  - `result_size/1` - Calculate the size of a result value
  - `error_type/1` - Extract error type from error value
  - `error_message/1` - Extract error message from error value
  """

  require Logger

  @doc """
  Extract reactor name from context.

  Tries to get the reactor name from various context fields with fallback
  to a default value.

  ## Examples

      iex> Reactor.Middleware.Utils.get_reactor_name(%{reactor_name: "MyReactor"})
      "MyReactor"

      iex> Reactor.Middleware.Utils.get_reactor_name(%{__reactor__: %{id: MyApp.TestReactor}})
      "Elixir.MyApp.TestReactor"

      iex> Reactor.Middleware.Utils.get_reactor_name(%{})
      "unknown_reactor"
  """
  @spec get_reactor_name(map()) :: String.t()
  def get_reactor_name(context) do
    case context do
      %{reactor_name: reactor_name} when is_binary(reactor_name) ->
        reactor_name

      %{__reactor__: %{id: reactor_module}} when is_atom(reactor_module) ->
        to_string(reactor_module)

      _ ->
        "unknown_reactor"
    end
  end

  @doc """
  Execute an operation with error handling and logging.

  Wraps the execution of a function in a try-rescue block to prevent
  middleware errors from crashing the reactor execution.

  ## Parameters

  - `operation` - Zero-arity function to execute
  - `module_name` - Name of the middleware module for error logging
  - `fallback` - Value to return if operation fails (defaults to `:ok`)

  ## Examples

      iex> Reactor.Middleware.Utils.safe_execute(fn -> {:ok, "success"} end, "TestMiddleware")
      {:ok, "success"}

      iex> Reactor.Middleware.Utils.safe_execute(fn -> raise "error" end, "TestMiddleware", :error)
      :error
  """
  @spec safe_execute((-> any()), any()) :: any()
  def safe_execute(operation, fallback \\ :ok) do
    operation.()
  rescue
    error ->
      Exception.format(:error, error, __STACKTRACE__) |> Logger.warning()
      Logger.warning("Middleware error: #{inspect(error, limit: 200)}")
      fallback
  end

  @doc """
  Calculate duration from context start time.

  Calculates the elapsed time from a start time stored in the context
  to the current time.

  ## Parameters

  - `context` - Context map containing start time
  - `start_time_key` - Key to look up start time in context

  ## Examples

      iex> context = %{my_start_time: System.monotonic_time()}
      iex> Process.sleep(10)
      iex> Reactor.Middleware.Utils.calculate_duration(context, :my_start_time)
      # Returns duration in milliseconds (approximately 10)
  """
  @spec calculate_duration(map(), atom()) :: non_neg_integer()
  def calculate_duration(context, start_time_key) do
    case Map.get(context, start_time_key) do
      nil ->
        0

      start_time ->
        System.convert_time_unit(
          System.monotonic_time() - start_time,
          :native,
          :millisecond
        )
    end
  end

  @doc """
  Get configuration value with fallback.

  Retrieves configuration for a middleware module from application config
  with a fallback to default value.

  ## Parameters

  - `module` - Middleware module atom
  - `key` - Configuration key
  - `default` - Default value if key not found

  ## Examples

      iex> Reactor.Middleware.Utils.get_config(MyMiddleware, :enabled, false)
      true
  """
  @spec get_config(module(), atom(), any()) :: any()
  def get_config(module, key, default) do
    # Get app config for this module
    app_config = Application.get_env(:area51, module)

    # Ensure app_config is a keyword list, default to empty list if not found or nil
    keyword_config = if is_list(app_config), do: app_config, else: []

    Keyword.get(keyword_config, key, default)
  end

  @doc """
  Determine the type of a result value.

  Returns a consistent type identifier for various Elixir data types.

  ## Parameters

  - `format` - Return format (`:atom` for atoms, `:string` for strings)

  ## Examples

      iex> Reactor.Middleware.Utils.result_type(%{key: "value"}, :atom)
      :map

      iex> Reactor.Middleware.Utils.result_type([1, 2, 3], :string)
      "list"
  """
  @spec result_type(any(), :atom | :string) :: atom() | String.t()
  def result_type(result, format \\ :atom) do
    type_atom = determine_type(result)
    format_type(type_atom, format)
  end

  defp determine_type(result) do
    cond do
      is_map(result) -> :map
      is_list(result) -> :list
      is_binary(result) -> :binary
      is_atom(result) -> :atom
      is_number(result) -> :number
      is_tuple(result) -> :tuple
      true -> :other
    end
  end

  defp format_type(type_atom, :atom), do: type_atom
  defp format_type(type_atom, :string), do: to_string(type_atom)

  @doc """
  Calculate the size of a result value.

  Returns the size/length of various data types in a consistent way.

  ## Examples

      iex> Reactor.Middleware.Utils.result_size(%{a: 1, b: 2})
      2

      iex> Reactor.Middleware.Utils.result_size([1, 2, 3, 4])
      4

      iex> Reactor.Middleware.Utils.result_size("hello")
      5
  """
  @spec result_size(any()) :: non_neg_integer()
  def result_size(result) when is_map(result), do: map_size(result)
  def result_size(result) when is_list(result), do: length(result)
  def result_size(result) when is_binary(result), do: byte_size(result)
  def result_size(result) when is_tuple(result), do: tuple_size(result)
  def result_size(_), do: 1

  @doc """
  Extract error type from error value.

  Determines the type of an error for consistent error categorization.

  ## Examples

      iex> Reactor.Middleware.Utils.error_type(:timeout)
      :timeout

      iex> Reactor.Middleware.Utils.error_type("Something went wrong")
      :string_error

      iex> Reactor.Middleware.Utils.error_type(%RuntimeError{message: "error"})
      RuntimeError
  """
  @spec error_type(any()) :: atom()
  def error_type(error) when is_atom(error), do: error
  def error_type(error) when is_binary(error), do: :string_error
  def error_type(%{__exception__: true} = error), do: error.__struct__
  def error_type({error_type, _}), do: error_type
  def error_type(_), do: :unknown_error

  @doc """
  Extract error message from error value.

  Extracts a human-readable message from various error types.

  ## Examples

      iex> Reactor.Middleware.Utils.error_message("Something went wrong")
      "Something went wrong"

      iex> Reactor.Middleware.Utils.error_message(:timeout)
      "timeout"

      iex> Reactor.Middleware.Utils.error_message(%RuntimeError{message: "error"})
      "error"
  """
  @spec error_message(any()) :: String.t()
  def error_message(error) when is_binary(error), do: error
  def error_message(error) when is_atom(error), do: to_string(error)
  def error_message(%{message: message}), do: message
  def error_message({_, message}) when is_binary(message), do: message
  def error_message(error), do: inspect(error, limit: 200)

  @doc """
  Calculate the duration of a step execution in milliseconds.

  Uses step start times stored in the process dictionary to calculate actual execution duration.
  If no start time is found, returns 0.

  ## Parameters

  - `step` - The reactor step
  - `context` - The reactor context (not used but kept for API compatibility)

  ## Examples

      iex> step = %Reactor.Step{name: "my_step"}
      iex> Reactor.Middleware.Utils.store_step_start_time("my_step")
      iex> :timer.sleep(100)
      iex> Reactor.Middleware.Utils.calculate_step_duration(step, %{})
      100  # approximately 100 milliseconds

  ## Notes

  This function uses the process dictionary to store step timing data with the key
  `{:step_timing, step_name}`. Step start times should be stored using `store_step_start_time/1,2`.
  """
  @spec calculate_step_duration(Reactor.Step.t(), map()) :: non_neg_integer()
  def calculate_step_duration(%Reactor.Step{name: step_name} = _step, _context) do
    step_name_str = to_string(step_name)
    timing_key = {:step_timing, step_name_str}

    duration =
      case Process.get(timing_key) do
        nil ->
          0

        start_time ->
          current_time = System.monotonic_time()

          System.convert_time_unit(
            current_time - start_time,
            :native,
            :millisecond
          )
      end

    cleanup_step_timing(step_name)
    duration
  end

  @doc """
  Store the start time for a step in the process dictionary.

  Uses the process dictionary to track when a step started for duration calculation.

  ## Parameters

  - `step_name` - The name of the step
  - `start_time` - The start time (defaults to current monotonic time)

  ## Examples

      iex> Reactor.Middleware.Utils.store_step_start_time("my_step")
      :ok

      iex> Reactor.Middleware.Utils.store_step_start_time("my_step", System.monotonic_time())
      :ok

  ## Notes

  This stores timing data in the process dictionary with the key `{:step_timing, step_name}`.
  The data is automatically cleaned up when the process ends.
  """
  @spec store_step_start_time(String.t() | atom(), integer() | nil) :: :ok
  def store_step_start_time(step_name, start_time \\ nil) do
    start_time = start_time || System.monotonic_time()
    step_name_str = to_string(step_name)
    timing_key = {:step_timing, step_name_str}

    Process.put(timing_key, start_time)
    :ok
  end

  @doc """
  Remove step timing data from the process dictionary.

  Cleans up step timing data after step completion to prevent memory buildup,
  although process dictionary data is automatically cleaned up when the process ends.

  ## Parameters

  - `step_name` - The name of the step to clean up

  ## Examples

      iex> Reactor.Middleware.Utils.cleanup_step_timing("my_step")
      :ok

  """
  @spec cleanup_step_timing(String.t() | atom()) :: :ok
  def cleanup_step_timing(step_name) do
    step_name_str = to_string(step_name)
    timing_key = {:step_timing, step_name_str}
    Process.delete(timing_key)
    :ok
  end

  @doc """
  Format step arguments for display.

  Converts a list of Reactor.Argument structs into a readable string format.

  ## Parameters

  - `arguments` - List of %Reactor.Argument{} structs
  - `limit` - Character limit for individual argument values (default: 50)

  ## Examples

      iex> args = [%Reactor.Argument{name: :input, source: %{data: "test"}}]
      iex> Reactor.Middleware.Utils.format_step_arguments(args)
      "input: %{data: \"test\"}"
  """
  @spec format_step_arguments(list(Reactor.Argument.t()), pos_integer()) :: String.t()
  def format_step_arguments(arguments, limit \\ 50)

  def format_step_arguments(arguments, limit) when is_list(arguments) do
    Enum.map_join(arguments, ", ", fn %Reactor.Argument{name: name, source: source} ->
      "#{name}: #{inspect(source, limit: limit)}"
    end)
  end

  def format_step_arguments(arguments, limit) do
    inspect(arguments, limit: limit)
  end

  @doc """
  Sanitize step arguments for logging.

  Converts step arguments to a safe format for logging, with size limits
  and sensitive data handling.

  ## Parameters

  - `arguments` - List of %Reactor.Argument{} structs
  - `max_size` - Maximum size for individual argument values (default: 1000)

  ## Examples

      iex> args = [%Reactor.Argument{name: :data, source: "sensitive"}]
      iex> Reactor.Middleware.Utils.sanitize_step_arguments(args)
      %{data: "sensitive"}
  """
  @spec sanitize_step_arguments(list(Reactor.Argument.t()), pos_integer()) :: map()
  def sanitize_step_arguments(arguments, max_size \\ 1000)

  def sanitize_step_arguments(arguments, max_size) when is_list(arguments) do
    arguments
    |> Enum.map(fn %Reactor.Argument{name: name, source: source} ->
      sanitized_source = sanitize_value(source, max_size)
      {name, sanitized_source}
    end)
    |> Enum.into(%{})
  end

  def sanitize_step_arguments(arguments, max_size) do
    inspect(arguments, limit: max_size)
  end

  @doc """
  Build comprehensive error information for logging and telemetry.

  Creates a structured error info map containing type, message, details, and stacktrace.

  ## Parameters

  - `error` - The error to analyze (any type)
  - `module` - The calling module for configuration context

  ## Examples

      iex> error = %RuntimeError{message: "Something went wrong"}
      iex> Reactor.Middleware.Utils.build_error_info(error, MyMiddleware)
      %{
        type: "Elixir.RuntimeError",
        message: "Something went wrong",
        details: "%RuntimeError{message: \"Something went wrong\"}",
        stacktrace: "..."
      }
  """
  @spec build_error_info(any(), module()) :: map()
  def build_error_info(error, module) do
    %{
      type: error_type(error) |> to_string(),
      message: error_message(error),
      details: error_details(error, module),
      stacktrace: format_stacktrace()
    }
  end

  # Private helper function for value sanitization
  defp sanitize_value(value, max_size) do
    inspected = inspect(value, limit: max_size)

    if String.length(inspected) > max_size do
      String.slice(inspected, 0, max_size) <> "...[truncated]"
    else
      inspected
    end
  end

  # Private helper function for error details extraction
  defp error_details(error, module) do
    case get_config(module, :include_error_details, true) do
      true -> inspect(error, limit: 500)
      false -> "error_details_disabled"
    end
  end

  # Private helper function for stacktrace formatting
  defp format_stacktrace do
    case Process.info(self(), :current_stacktrace) do
      {:current_stacktrace, stacktrace} ->
        stacktrace
        # Limit stacktrace depth
        |> Enum.take(10)
        |> Enum.map_join("\n", &Exception.format_stacktrace_entry/1)

      _ ->
        "stacktrace_unavailable"
    end
  end
end
