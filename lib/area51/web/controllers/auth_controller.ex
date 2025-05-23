defmodule Area51.Web.AuthController do
  use Area51.Web, :controller
  alias Area51.Web.Auth.Guardian

  # API endpoint to verify a token and return the user info
  def verify(conn, %{"token" => token}) do
    case Guardian.verify_and_get_user_info(token) do
      {:ok, user} ->
        json(conn, %{valid: true, user: user})

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{valid: false, error: "Invalid token: #{reason}"})
    end
  end
end
