defmodule Area51.Web.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  alias Area51.Jobs.ObanTelemetryHandler
  alias Area51.Web.Endpoint
  @impl true
  def start(_type, _args) do
    # Initialize OpenTelemetry
    setup_opentelemetry()

    # Attach Oban telemetry handlers
    ObanTelemetryHandler.attach_handlers()

    children = [
      Area51.Data.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:area51, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:area51, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Area51.Data.PubSub},
      {Oban, Application.fetch_env!(:area51, Oban)},
      Area51.Web.Telemetry,
      Area51.Web.PromEx,
      Area51.Web.Auth.Guardian.Strategy,
      # Start to serve requests, typically the last entry
      Area51.Web.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Area51.Web.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  # Set up OpenTelemetry with our custom configuration
  defp setup_opentelemetry do
    :ok = OpentelemetryBandit.setup()
    # Initialize Phoenix instrumentation
    :ok = OpentelemetryPhoenix.setup(adapter: :bandit)
    # Initialize Ecto instrumentation
    :ok = OpentelemetryEcto.setup([Area51.Data.Repo])

    Logger.info(
      "OpenTelemetry configured with exporter: #{inspect(Application.get_env(:opentelemetry, :traces_exporter))}"
    )
  end

  defp skip_migrations? do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
