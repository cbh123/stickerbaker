defmodule EmojiWeb.ErrorJSONTest do
  use EmojiWeb.ConnCase, async: true

  test "renders 404" do
    assert EmojiWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert EmojiWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
