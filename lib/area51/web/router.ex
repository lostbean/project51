defmodule Area51.Web.Router do
  use Area51.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery

    plug :put_secure_browser_headers,
         Application.compile_env!(:area51, Area51.Web.Endpoint)[:secure_browser_headers]
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug Area51.Web.Plugs.RequireAuth
  end

  # Public API endpoints
  scope "/api", Area51.Web do
    pipe_through :api

    # Authentication endpoints
    scope "/auth" do
      # Token verification endpoint
      post "/verify", AuthController, :verify
    end

    # Mystery generation endpoints
    scope "/mysteries" do
      post "/generate-async", MysteryController, :generate_async
      get "/job/:job_id", MysteryController, :job_status
      get "/jobs", MysteryController, :list_jobs
      delete "/job/:job_id", MysteryController, :cancel_job
    end
  end

  # Protected API endpoints
  scope "/api/secure", Area51.Web do
    pipe_through [:api_auth]

    # Protected endpoints here
  end

  scope "/", Area51.Web do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:area51, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: Area51.Web.Telemetry
    end
  end
end
