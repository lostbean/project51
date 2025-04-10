defmodule Area51Gleam.MixProject do
  use Mix.Project

  @app :area51_gleam

  def project do
    [
      app: @app,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~>1.4"},
      # Gleam deps
      {:gleam_state, path: "../../gleam_state/"},
      {:gleam_stdlib, "~> 0.59"},
      {:gleam_json, "~> 2.3.0"},
      {:gleeunit, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      setup: []
    ]
  end
end
