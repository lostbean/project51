defmodule Area51.Web.PromEx do
  use PromEx, otp_app: :area51

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      # PromEx built in plugins
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: Area51.Web.Router, endpoint: Area51.Web.Endpoint},
      {Plugins.Ecto, repos: [Area51.Data.Repo]}
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      # name of the Prometheus datasource in Grafana
      datasource_id: "prometheus",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      # PromEx built in Grafana dashboards
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "ecto.json"}

      # Add your dashboard definitions here with the format: {:otp_app, "path_in_priv"}
      # {:area51_web, "/grafana_dashboards/user_metrics.json"}
    ]
  end
end
