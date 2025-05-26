defmodule Reactor.Middleware.Config do
  @moduledoc """
  Configuration utilities for Reactor middleware.

  This module provides utilities for validating and managing middleware configuration,
  including runtime configuration adjustments and environment-specific overrides.

  ## Usage

      # Validate all middleware configurations at startup
      Reactor.Middleware.Config.validate_all_configs()

      # Get validated configuration for a specific middleware
      config = Reactor.Middleware.Config.get_middleware_config(
        Reactor.Middleware.OpenTelemetryMiddleware
      )

      # Check if instrumentation should be enabled based on environment
      enabled? = Reactor.Middleware.Config.instrumentation_enabled?()
  """

  require Logger

  @middleware_modules [
    Reactor.Middleware.OpenTelemetryMiddleware,
    Reactor.Middleware.StructuredLoggingMiddleware,
    Reactor.Middleware.TelemetryEventsMiddleware
  ]

  @doc """
  Validates configuration for all middleware modules.

  This should be called during application startup to ensure all configurations
  are valid and set appropriate defaults.
  """
  def validate_all_configs do
    Enum.each(@middleware_modules, &validate_config/1)
  end

  @doc """
  Validates and normalizes configuration for a specific middleware module.

  Returns the validated configuration and logs any issues found.
  """
  def validate_config(middleware_module) do
    config = Application.get_env(:area51, middleware_module, [])

    validated_config =
      config
      |> validate_enabled()
      |> validate_module_specific_config(middleware_module)
      |> apply_environment_overrides(middleware_module)

    Application.put_env(:area51, middleware_module, validated_config)
    validated_config
  end

  @doc """
  Gets the validated configuration for a middleware module.

  This applies runtime overrides and environment-specific settings.
  """
  def get_middleware_config(middleware_module) do
    base_config = Application.get_env(:area51, middleware_module, [])

    runtime_overrides = get_runtime_overrides()
    environment_overrides = get_environment_overrides(middleware_module)

    base_config
    |> Keyword.merge(environment_overrides)
    |> Keyword.merge(runtime_overrides)
  end

  @doc """
  Checks if instrumentation should be enabled based on global settings.

  This considers environment variables, application config, and runtime conditions.
  """
  def instrumentation_enabled? do
    case System.get_env("INSTRUMENTATION_ENABLED") do
      "false" ->
        false

      "0" ->
        false

      _ ->
        Application.get_env(:area51, :instrumentation_enabled, true)
    end
  end

  @doc """
  Gets the instrumentation level from environment or config.

  Returns one of: :minimal, :standard, :debug, :disabled
  """
  def get_instrumentation_level do
    env_level = System.get_env("INSTRUMENTATION_LEVEL", "standard")
    config_level = Application.get_env(:area51, :instrumentation_level, :standard)

    case env_level do
      "minimal" -> :minimal
      "standard" -> :standard
      "debug" -> :debug
      "disabled" -> :disabled
      _ -> config_level
    end
  end

  @doc """
  Applies instrumentation level settings to middleware configuration.
  """
  def apply_instrumentation_level(config, level) do
    case level do
      :disabled ->
        Keyword.put(config, :enabled, false)

      :minimal ->
        config
        |> Keyword.put(:enabled, true)
        |> Keyword.put(:include_arguments, false)
        |> Keyword.put(:include_results, false)
        |> Keyword.put(:include_metadata, false)
        |> Keyword.put(:log_level, :warning)

      :standard ->
        config
        |> Keyword.put(:enabled, true)
        |> Keyword.put(:include_arguments, false)
        |> Keyword.put(:include_results, false)
        |> Keyword.put(:include_metadata, true)
        |> Keyword.put(:log_level, :info)

      :debug ->
        config
        |> Keyword.put(:enabled, true)
        |> Keyword.put(:include_arguments, true)
        |> Keyword.put(:include_results, true)
        |> Keyword.put(:include_metadata, true)
        |> Keyword.put(:log_level, :debug)

      _ ->
        config
    end
  end

  # Private functions

  defp validate_enabled(config) do
    case Keyword.get(config, :enabled) do
      nil ->
        default_enabled = instrumentation_enabled?()
        Keyword.put(config, :enabled, default_enabled)

      val when is_boolean(val) ->
        config

      _ ->
        Logger.warning("Invalid :enabled config, defaulting to true")
        Keyword.put(config, :enabled, true)
    end
  end

  defp validate_module_specific_config(config, Reactor.Middleware.OpenTelemetryMiddleware) do
    config
    |> validate_span_attributes()
    |> validate_include_arguments()
    |> validate_include_results()
  end

  defp validate_module_specific_config(config, Reactor.Middleware.StructuredLoggingMiddleware) do
    config
    |> validate_log_level()
    |> validate_include_arguments()
    |> validate_include_results()
    |> validate_max_argument_size()
  end

  defp validate_module_specific_config(config, Reactor.Middleware.TelemetryEventsMiddleware) do
    config
    |> validate_event_prefix()
    |> validate_include_metadata()
  end

  defp validate_module_specific_config(config, _), do: config

  defp validate_span_attributes(config) do
    case Keyword.get(config, :span_attributes) do
      nil ->
        default_attrs = [
          service_name: "area51",
          service_version: Application.spec(:area51, :vsn) || "unknown"
        ]

        Keyword.put(config, :span_attributes, default_attrs)

      attrs when is_list(attrs) ->
        config

      _ ->
        Logger.warning("Invalid :span_attributes config, using defaults")
        Keyword.put(config, :span_attributes, [])
    end
  end

  defp validate_log_level(config) do
    valid_levels = [:emergency, :alert, :critical, :error, :warning, :notice, :info, :debug]

    level = Keyword.get(config, :log_level, :info)

    if level in valid_levels do
      config
    else
      Logger.warning("Invalid :log_level config, defaulting to :info")
      Keyword.put(config, :log_level, :info)
    end
  end

  defp validate_event_prefix(config) do
    case Keyword.get(config, :event_prefix) do
      nil ->
        Keyword.put(config, :event_prefix, [:reactor])

      prefix when is_list(prefix) and length(prefix) > 0 ->
        # Validate that all elements are atoms
        if Enum.all?(prefix, &is_atom/1) do
          config
        else
          Logger.warning("Invalid :event_prefix config, must be list of atoms")
          Keyword.put(config, :event_prefix, [:reactor])
        end

      _ ->
        Logger.warning("Invalid :event_prefix config, defaulting to [:reactor]")
        Keyword.put(config, :event_prefix, [:reactor])
    end
  end

  defp validate_include_arguments(config) do
    case Keyword.get(config, :include_arguments) do
      nil ->
        Keyword.put(config, :include_arguments, false)

      val when is_boolean(val) ->
        config

      _ ->
        Logger.warning("Invalid :include_arguments config, defaulting to false")
        Keyword.put(config, :include_arguments, false)
    end
  end

  defp validate_include_results(config) do
    case Keyword.get(config, :include_results) do
      nil ->
        Keyword.put(config, :include_results, false)

      val when is_boolean(val) ->
        config

      _ ->
        Logger.warning("Invalid :include_results config, defaulting to false")
        Keyword.put(config, :include_results, false)
    end
  end

  defp validate_include_metadata(config) do
    case Keyword.get(config, :include_metadata) do
      nil ->
        Keyword.put(config, :include_metadata, true)

      val when is_boolean(val) ->
        config

      _ ->
        Logger.warning("Invalid :include_metadata config, defaulting to true")
        Keyword.put(config, :include_metadata, true)
    end
  end

  defp validate_max_argument_size(config) do
    case Keyword.get(config, :max_argument_size) do
      nil ->
        Keyword.put(config, :max_argument_size, 1000)

      size when is_integer(size) and size > 0 ->
        config

      _ ->
        Logger.warning("Invalid :max_argument_size config, defaulting to 1000")
        Keyword.put(config, :max_argument_size, 1000)
    end
  end

  defp apply_environment_overrides(config, _middleware_module) do
    level = get_instrumentation_level()
    apply_instrumentation_level(config, level)
  end

  defp get_runtime_overrides do
    []
    |> apply_enabled_override()
    |> apply_log_level_override()
    |> apply_include_args_override()
  end

  defp apply_enabled_override(overrides) do
    case System.get_env("INSTRUMENTATION_ENABLED") do
      "false" -> [{:enabled, false} | overrides]
      "0" -> [{:enabled, false} | overrides]
      "true" -> [{:enabled, true} | overrides]
      "1" -> [{:enabled, true} | overrides]
      _ -> overrides
    end
  end

  defp apply_log_level_override(overrides) do
    case System.get_env("INSTRUMENTATION_LOG_LEVEL") do
      level when level in ["debug", "info", "warning", "error"] ->
        [{:log_level, String.to_atom(level)} | overrides]

      _ ->
        overrides
    end
  end

  defp apply_include_args_override(overrides) do
    case System.get_env("INSTRUMENTATION_INCLUDE_ARGS") do
      "true" -> [{:include_arguments, true} | overrides]
      "false" -> [{:include_arguments, false} | overrides]
      _ -> overrides
    end
  end

  defp get_environment_overrides(_middleware_module) do
    # Use Application environment instead of Mix.env() for runtime compatibility
    env = Application.get_env(:area51, :environment, :prod)

    case env do
      :test ->
        # Disable instrumentation in tests by default for performance
        [
          enabled: false,
          log_level: :warning
        ]

      :dev ->
        # Enable debug mode in development
        [
          include_arguments: true,
          include_results: true,
          log_level: :debug
        ]

      :prod ->
        # Production settings prioritize performance and security
        [
          include_arguments: false,
          include_results: false,
          log_level: :info,
          max_argument_size: 500
        ]

      _ ->
        []
    end
  end
end
