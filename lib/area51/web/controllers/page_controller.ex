defmodule Area51.Web.PageController do
  use Area51.Web, :controller

  def index(conn, _params) do
    render(conn, :home, layout: false)
  end
end
