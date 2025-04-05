defmodule Area51Web.Plugs.RequireAuth do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :current_user) do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{error: "You must be logged in to access this resource"})
      |> halt()
    end
  end
end
