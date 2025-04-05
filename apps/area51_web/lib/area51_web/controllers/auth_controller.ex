defmodule Area51Web.AuthController do
  use Area51Web, :controller
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user = %{
      id: auth.uid,
      email: auth.info.email,
      name: auth.info.name || auth.info.nickname || auth.info.email,
      avatar: auth.info.image
    }

    # Store user in session
    conn
    |> put_session(:current_user, user)
    |> configure_session(renew: true)
    |> redirect(to: "/")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def logout(conn, _params) do
    domain = Application.get_env(:ueberauth, Ueberauth.Strategy.Auth0.OAuth)[:domain]
    client_id = Application.get_env(:ueberauth, Ueberauth.Strategy.Auth0.OAuth)[:client_id]
    return_to = url(~p"/")

    # Construct Auth0 logout URL
    logout_url =
      "https://#{domain}/v2/logout?" <>
        "client_id=#{client_id}&returnTo=#{URI.encode_www_form(return_to)}"

    conn
    |> configure_session(drop: true)
    |> redirect(external: logout_url)
  end

  # API session check
  def session(conn, _params) do
    current_user = get_session(conn, :current_user)

    if current_user do
      json(conn, %{authenticated: true, user: current_user})
    else
      json(conn, %{authenticated: false, user: nil})
    end
  end
end
