defmodule Area51.Web.ErrorJSONTest do
  use Area51.Web.ConnCase, async: true

  test "renders 404" do
    assert Area51.Web.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert Area51.Web.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
