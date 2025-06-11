defmodule Area51.MixProject do
  use Mix.Project

  @app :area51
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.18",
      name: "#{@app}",
      archives: [mix_gleam: "~> 0.6.2"],
      compilers: [:gleam] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      erlc_paths: [
        "build/dev/erlang/#{@app}/_gleam_artefacts",
        # For Gleam < v0.25.0
        "build/dev/erlang/#{@app}/build"
      ],
      erlc_include_path: "build/dev/erlang/#{@app}/include",
      # For Elixir >= v1.15.0
      prune_code_paths: false,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # Assuming Area51.Web.Application is the main entry point
      mod: {Area51.Web.Application, []},
      extra_applications: [:logger, :runtime_tools, :tls_certificate_check]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/area51/data/support", "test/area51/web/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # From area51_core
      {:jason, "~> 1.4"},

      # From area51_data
      {:dns_cluster, "~> 0.1.1"},
      {:phoenix_pubsub, "~> 2.1"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, ">= 0.0.0"},

      # From area51_gleam
      {:gleam_state, path: "./gleam_state"},
      {:gleam_stdlib, "~> 0.59"},
      {:gleam_json, "~> 2.3.0"},
      {:gleeunit, "~> 1.0", [only: [:dev, :test], runtime: false]},

      # From area51_llm
      {:magus, "~> 0.2.0"},
      {:langchain, "~> 0.3.2"},
      {:reactor, "~> 0.15.2"},
      {:instructor, "~> 0.1.0"},
      {:typed_struct, "~> 0.3"},
      {:oban, "~> 2.19"},

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
      {:opentelemetry_oban, "~> 1.1"},

      # Also in extra_applications
      {:opentelemetry, "~> 1.5"},
      {:opentelemetry_api, "~> 1.4"},
      {:opentelemetry_semantic_conventions, "~> 1.27", override: true},
      {:tls_certificate_check, "~> 1.27"},
      {:prom_ex, "~> 1.11.0"},

      # Testing
      {:meck, "~> 1.0", only: :test},
      {:mimic, "~> 1.11.2", only: :test},

      # Code Quality & Analysis Tools
      {:tidewave, "~> 0.1", only: :dev},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", runtime: false}
    ]
  end

  defp aliases do
    [
      "deps.get": ["deps.get", "gleam.deps.get"],
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run #{__DIR__}/priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test --trace"],
      "assets.setup": ["cmd --cd assets npm install"],
      "assets.build": ["cmd --cd assets node build.js"],
      "assets.deploy": ["cmd --cd assets node build.js --deploy", "phx.digest"],
      # Our new check alias
      check: [
        "compile",
        "format --check-formatted",
        "credo --strict",
        "dialyzer",
        "sobelow --skip --exit",
        "test",
        # Optional: ensures docs can be built
        "docs"
      ]
    ]
  end
end
