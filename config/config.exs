# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :area51,
  ecto_repos: [Area51.Data.Repo]

config :area51,
  ecto_repos: [Area51.Data.Repo],
  generators: [context_app: :area51]

# Configures the endpoint
config :area51, Area51.Web.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: Area51.Web.ErrorJSON],
    layout: false
  ],
  pubsub_server: Area51.Data.PubSub,
  live_view: [signing_salt: "2ZG5S4yv"],
  secure_browser_headers: %{
    "content-security-policy" =>
      "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; object-src 'none'; frame-ancestors 'none';"
  }

# Configures Elixir's Logger
config :logger, :console,
  format: "$time [$level] $message $metadata\n",
  metadata: [:mfa, :pid, :crash_reason, :initial_call, :application]

config :area51, Area51.Web.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  # Use grafana: :disabled to stop uploading updated generated dashboard at startup
  grafana: [host: "http://grafana:3000"],
  metrics_server: :disabled

config :area51, Reactor.Middleware.OpenTelemetryMiddleware,
  enabled: true,
  span_attributes: [
    service_name: "area51",
    service_version: "1.0.0"
  ],
  # For security
  include_arguments: true,
  # For security
  include_results: true

config :area51, Reactor.Middleware.StructuredLoggingMiddleware,
  enabled: true,
  log_level: :info,
  include_arguments: true,
  include_results: true,
  max_argument_size: 1000

config :area51, Reactor.Middleware.TelemetryEventsMiddleware,
  enabled: true,
  event_prefix: [:reactor],
  include_metadata: true

# Configure LiveState
config :live_state,
  otp_app: :area51

# Configure CORS for LiveState (adjust as needed)
config :cors_plug,
  origin: "*",
  methods: [:get, :post, :put, :delete, :options],
  headers: ["content-type"]

config :esbuild,
  version: "0.18.6",
  default: [
    args: ~w(js/app.tsx --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__)
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure JWKS for JWT validation
config :area51, Area51.Web.Auth.Guardian.Strategy, jwks_url: System.get_env("APP_AUTH0_JWKS_URL")

# Configure OpenTelemetry
config :opentelemetry, :resource, service: %{name: "area51"}

config :opentelemetry,
  span_processor: :batch,
  traces_exporter: :otlp

config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: System.get_env("OTLP_ENDPOINT")

# Configure OpenTelemetry Phoenix instrumenter
config :opentelemetry_phoenix, :trace_options,
  disabled_routers: [],
  disabled_paths: []

# Configure Phoenix to use OpenTelemetry instrumenter
config :phoenix, :instrumenters, [OpenTelemetry.Phoenix.Instrumenter]

# Configure Ecto to use OpenTelemetry
config :area51, Area51.Data.Repo, telemetry_prefix: [:area51_data, :repo]

config :opentelemetry_ecto, tracer_id: :area51_tracer

# Configure Oban
config :area51, Oban,
  engine: Oban.Engines.Basic,
  repo: Area51.Data.Repo,
  # Use PG notifier
  notifier: Oban.Notifiers.PG,
  # Disable peer system for SQLite3 compatibility
  peer: false,
  # Disable table prefixes for SQLite3 compatibility
  prefix: false,
  plugins: [
    # Keep jobs for 7 days
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    # Enable cron scheduling if needed
    {Oban.Plugins.Cron, crontab: []},
    # Rescue orphaned jobs
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(30)}
  ],
  queues: [
    # Allow 2 concurrent mystery generation jobs
    mystery_generation: 2,
    default: 5
  ],
  dispatch_cooldown: 5

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
