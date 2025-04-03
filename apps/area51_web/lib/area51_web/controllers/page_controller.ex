defmodule Area51Web.PageController do
  use Area51Web, :controller

  def index(conn, _params) do
    conn
    |> put_resp_header("content-type", "text/html; charset=utf-8")
    |> Plug.Conn.send_file(200, Application.app_dir(:area51_web, "priv/static/index.html"))
  end
end
