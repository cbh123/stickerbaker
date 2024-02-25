defmodule StickerWeb.SessionController do
  use StickerWeb, :controller

  def set(conn, %{"local_user_id" => user_id}), do: store_string(conn, :local_user_id, user_id)

  defp store_string(conn, key, value) do
    conn
    |> put_session(key, value)
    |> json("OK!")
  end
end
