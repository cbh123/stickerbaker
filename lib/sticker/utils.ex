defmodule Sticker.Utils do
  require Logger

  def save_r2(file_name, image_url) do
    image_binary = Req.get!(image_url).body
    bucket = System.fetch_env!("BUCKET_NAME")

    %{status_code: 200} =
      bucket
      |> ExAws.S3.put_object(file_name, image_binary)
      |> ExAws.request!()

    "#{System.get_env("AWS_PUBLIC_URL")}/#{bucket}/#{file_name}"
  end

  def get_host() do
    case StickerWeb.Endpoint.host() do
      "localhost" ->
        Logger.warning("WE ARE IN LOCALHOST — IS NGROK SETUP?")
        System.get_env("NGROK_URL")

      url ->
        url
    end
  end
end
