defmodule Area51Data.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Area51Data.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:area51_data, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:area51_data, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Area51Data.PubSub}
      # Start a worker by calling: Area51Data.Worker.start_link(arg)
      # {Area51Data.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Area51Data.Supervisor)
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
