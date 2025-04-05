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
config :area51_data,
  ecto_repos: [Area51Data.Repo]

config :area51_web,
  ecto_repos: [Area51Data.Repo],
  generators: [context_app: :area51]

# Configures the endpoint
config :area51_web, Area51Web.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: Area51Web.ErrorJSON],
    layout: false
  ],
  pubsub_server: Area51Data.PubSub,
  live_view: [signing_salt: "2ZG5S4yv"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure LiveState
config :live_state,
  otp_app: :area51_web

# Configure CORS for LiveState (adjust as needed)
config :cors_plug,
  origin: "*",
  methods: [:get, :post, :put, :delete, :options],
  headers: ["content-type"]

config :esbuild,
  version: "0.18.6",
  default: [
    args: ~w(js/app.tsx --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../apps/area51_web/assets", __DIR__)
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Uberauth and Auth0
config :ueberauth, Ueberauth,
  providers: [
    auth0: {Ueberauth.Strategy.Auth0, []}
  ]

config :ueberauth, Ueberauth.Strategy.Auth0.OAuth,
  domain: System.get_env("APP_AUTH0_DOMAIN") || "MISSING_APP_AUTH0_DOMAIN",
  client_id: System.get_env("APP_AUTH0_CLIENT_ID") || "MISSING_APP_AUTH0_CLIENT_ID",
  client_secret: System.get_env("APP_AUTH0_CLIENT_SECRET") || "MISSING_APP_AUTH0_CLIENT_SECRET"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
