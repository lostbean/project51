defmodule Area51Web.Plugs.RequireAuth do
  @moduledoc """
  Plug to ensure a user is authenticated with a valid JWT
  """
  import Plug.Conn
  import Phoenix.Controller
  alias Area51Web.Auth.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, user} <- Guardian.verify_and_get_user_info(token) do
      # Store the user in conn assigns for later use
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "You must be logged in to access this resource"})
        |> halt()
    end
  end
end
