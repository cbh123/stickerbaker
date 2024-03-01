defmodule Sticker.Utils do
  require Logger

  def parse_prompt_classifier_output(output) do
    output
    |> Enum.join()
    |> String.trim()
    |> Float.parse()
    |> case do
      {float, _str} -> float |> round()
      :error -> 10
    end
  end

  def save_r2(file_name, image_url) do
    image_binary = Req.get!(image_url).body
    bucket = System.fetch_env!("BUCKET_NAME")

    %{status_code: 200} =
      bucket
      |> ExAws.S3.put_object(file_name, image_binary, content_type: "image/png")
      |> ExAws.request!()

    "#{System.get_env("AWS_PUBLIC_URL")}/#{bucket}/#{file_name}"
  end

  def get_host() do
    case StickerWeb.Endpoint.host() do
      "localhost" ->
        Logger.warning("WE ARE IN LOCALHOST — IS NGROK SETUP?")
        System.fetch_env!("NGROK_URL")

      host ->
        "https://#{host}"
    end
  end

  def base64_to_data_uri(base64, mime_type \\ "image/png") do
    "data:#{mime_type};base64," <> base64
  end
end
