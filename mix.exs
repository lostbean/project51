defmodule Area51.MixProject do
  use Mix.Project

  def project do
    [
      app: :area51,
      version: "0.1.0",
      elixir: "~> 1.18", # Using the highest version specified across apps
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: [
        area51: [
          applications: [area51: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Area51.Web.Application, []}, # Assuming Area51.Web.Application is the main entry point
      extra_applications: [:logger, :runtime_tools, :tls_certificate_check]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/area51/data/support", "test/area51/web/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # From area51_core
      {:jason, "~> 1.4"}, # Updated from 1.2 in data/web to 1.4 from core/gleam

      # From area51_data
      {:dns_cluster, "~> 0.1.1"},
      {:phoenix_pubsub, "~> 2.1"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, ">= 0.0.0"},

      # From area51_gleam
      {:gleam_state, path: "gleam_state/"}, # Adjusted path from ../../gleam_state
      {:gleam_stdlib, "~> 0.59"},
      {:gleam_json, "~> 2.3.0"},
      {:gleeunit, "~> 1.0"},

      # From area51_llm
      {:magus, "~> 0.2.0"},
      {:langchain, "~> 0.3.2"},
      {:opentelemetry, "~> 1.5"}, # Common with web
      {:opentelemetry_api, "~> 1.4"}, # Common with web
      {:opentelemetry_semantic_conventions, "~> 1.27"}, # Common with web

      # From area51_web
      {:cors_plug, "~> 3.0"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:live_state, "~> 0.8.1"},
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:bandit, "~> 1.5"},
      {:joken, "~> 2.6"},
      {:joken_jwks, "~> 1.7"},
      {:tesla, "~> 1.14"},
      {:hackney, "~> 1.23"},
      {:opentelemetry_exporter, "~> 1.8"},
      {:opentelemetry_phoenix, "~> 2.0"},
      {:opentelemetry_bandit, "~> 0.2.0"},
      {:opentelemetry_ecto, "~> 1.2"},
      {:opentelemetry_process_propagator, "~> 0.3"},
      {:tls_certificate_check, "~> 1.27"}, # Also in extra_applications
      {:prom_ex, "~> 1.11.0"},
      {:meck, "~> 1.0", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"], # Adjusted path for seeds
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      # Assuming 'assets' directory is at the project root (project51/assets)
      "assets.setup": ["cmd --cd assets npm install"],
      "assets.build": ["cmd --cd assets node build.js"],
      "assets.deploy": ["cmd --cd assets node build.js --deploy", "phx.digest"]
    ]
  end
end