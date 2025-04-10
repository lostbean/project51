defmodule Area51Web.MixProject do
  use Mix.Project

  def project do
    [
      app: :area51_web,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Area51Web.Application, []},
      extra_applications: [:logger, :runtime_tools, :tls_certificate_check]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:cors_plug, "~> 3.0"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:live_state, "~> 0.8.1"},
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:area51_data, in_umbrella: true},
      {:area51_core, in_umbrella: true},
      {:area51_llm, in_umbrella: true},
      {:jason, "~> 1.2"},
      {:bandit, "~> 1.5"},

      # Local gleam dependencies
      {:area51_gleam, in_umbrella: true},

      # Authentication
      # JWT Token verification
      {:joken, "~> 2.6"},
      {:joken_jwks, "~> 1.7"},
      {:tesla, "~> 1.14"},
      {:hackney, "~> 1.23"},

      # OpenTelemetry
      {:opentelemetry, "~> 1.5"},
      {:opentelemetry_api, "~> 1.4"},
      {:opentelemetry_exporter, "~> 1.8"},
      {:opentelemetry_phoenix, "~> 2.0"},
      {:opentelemetry_bandit, "~> 0.2.0"},
      {:opentelemetry_ecto, "~> 1.2"},
      {:opentelemetry_process_propagator, "~> 0.3"},
      {:opentelemetry_semantic_conventions, "~> 1.27"},
      # OTLP export needs to validate https connections - started on extra_applications
      {:tls_certificate_check, "~> 1.27"},
      {:prom_ex, "~> 1.11.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["assets.setup", "assets.build"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["cmd --cd assets npm install"],
      "assets.build": ["cmd --cd assets node build.js"],
      "assets.deploy": ["cmd --cd assets node build.js --deploy", "phx.digest"]
    ]
  end
end
