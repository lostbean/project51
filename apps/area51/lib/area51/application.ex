defmodule Area51.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Area51.Repo,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:area51, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:area51, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Area51.PubSub}
      # Start a worker by calling: Area51.Worker.start_link(arg)
      # {Area51.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Area51.Supervisor)
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
