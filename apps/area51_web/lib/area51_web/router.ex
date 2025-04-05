defmodule Area51Web.Router do
  use Area51Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug :fetch_session
    plug Area51Web.Plugs.RequireAuth
  end

  # Auth routes
  scope "/auth", Area51Web do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    get "/logout", AuthController, :logout
  end

  # Public API endpoints
  scope "/api", Area51Web do
    pipe_through :api

    get "/session", AuthController, :session
  end

  # Protected API endpoints
  scope "/api/secure", Area51Web do
    pipe_through [:api_auth]

    # Protected endpoints here
  end

  scope "/", Area51Web do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:area51_web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: Area51Web.Telemetry
    end
  end
end
