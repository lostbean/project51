defmodule Area51.Web.PageController do
  use Area51.Web, :controller

  # sobelow_skip ["Traversal"]
  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> Plug.Conn.send_file(200, Application.app_dir(:area51, "priv/static/index.html"))
  end
end
