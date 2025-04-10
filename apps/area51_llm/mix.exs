defmodule Area51LLM.MixProject do
  use Mix.Project

  def project do
    [
      app: :area51_llm,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
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
      {:magus, "~> 0.2.0"},
      {:langchain, "~> 0.3.2"},

      # OpenTelemetry
      {:opentelemetry, "~> 1.5"},
      {:opentelemetry_api, "~> 1.4"},
      {:opentelemetry_semantic_conventions, "~> 1.27"}
    ]
  end

  defp aliases do
    [
      setup: []
    ]
  end
end
