defmodule Area51Web.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Initialize OpenTelemetry
    setup_opentelemetry()

    children = [
      Area51Web.Telemetry,
      Area51Web.Auth.Guardian.Strategy,
      # Start to serve requests, typically the last entry
      Area51Web.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Area51Web.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Area51Web.Endpoint.config_change(changed, removed)
    :ok
  end

  # Set up OpenTelemetry with our custom configuration
  defp setup_opentelemetry do
    :ok = OpentelemetryBandit.setup()
    # Initialize Phoenix instrumentation
    :ok = OpentelemetryPhoenix.setup(adapter: :bandit)
    # Initialize Ecto instrumentation
    :ok = OpentelemetryEcto.setup([:area51_data, :repo])

    Logger.info(
      "OpenTelemetry configured with exporter: #{inspect(Application.get_env(:opentelemetry, :traces_exporter))}"
    )
  end
end
