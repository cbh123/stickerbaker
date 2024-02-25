defmodule StickerWeb.ReplicateWebhookController do
  use StickerWeb, :controller
  alias Sticker.Predictions

  def handle(conn, params) do
    handle_webhook(conn, params)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
  end

  def handle_webhook(
        conn,
        %{
          "status" => status,
          "output" => output,
          "user_id" => user_id,
          "prediction_id" => prediction_id,
          "model" => "fofr/prompt-classifier"
        }
      ) do
    rating = output |> Enum.join() |> String.trim()

    case status do
      "succeeded" ->
        rating = String.to_integer(rating)

        {:ok, prediction} =
          prediction_id
          |> Predictions.get_prediction!()
          |> Predictions.update_prediction(%{
            moderator: "fofr/prompt-classifier",
            moderation_score: rating,
            status: :moderation_succeeded
          })

        broadcast(user_id, {:moderation_complete, prediction})

        # automatically kick off gen image step
        if rating < 9 do
          gen_image(prediction.prompt, user_id, prediction.id)
        end

      "failed" ->
        broadcast(user_id, {:moderation_failed, "Something went wrong...try again?"})

      status ->
        IO.inspect("status is... #{status}")
    end

    conn
  end

  def handle_webhook(
        conn,
        %{
          "status" => status,
          "output" => output,
          "id" => uuid,
          "user_id" => user_id,
          "model" => "fofr/sticker-maker",
          "prediction_id" => prediction_id
        }
      ) do
    prediction = prediction_id |> Predictions.get_prediction!()

    case status do
      "succeeded" ->
        r2_url =
          save_r2(
            "prediction-#{prediction_id}-sticker.png",
            output |> List.last()
          )

        {:ok, prediction} =
          Predictions.update_prediction(prediction, %{
            uuid: uuid,
            sticker_output: r2_url,
            status: :succeeded
          })

        broadcast(user_id, {:prediction_completed, prediction})

      "failed" ->
        {:ok, prediction} =
          Predictions.update_prediction(prediction, %{uuid: uuid, status: :failed})

        broadcast(user_id, {:prediction_failed, prediction})

      "processing" ->
        {:ok, prediction} =
          Predictions.update_prediction(prediction, %{status: :processing})

        broadcast(user_id, {:prediction_loading, prediction})

      status ->
        IO.puts("status is... #{status}")
    end

    conn
  end

  defp broadcast(user_id, message),
    do: Phoenix.PubSub.broadcast(Sticker.PubSub, "user:#{user_id}", message)

  defp gen_image(prompt, user_id, prediction_id) do
    "fofr/sticker-maker"
    |> Replicate.Models.get!()
    |> Replicate.Models.get_latest_version!()
    |> Replicate.Predictions.create(
      %{
        prompt: prompt,
        width: 512,
        height: 512,
        num_inference_steps: 20,
        negative_prompt: "racist, xenophobic, antisemitic, islamophobic, bigoted",
        upscale: false
      },
      "https://db8d-2001-5a8-4288-b400-65d8-9a7e-4a09-ae40.ngrok-free.app/webhooks/replicate?user_id=#{user_id}&prediction_id=#{prediction_id}"
    )
  end

  def save_r2(file_name, image_url) do
    image_binary = Req.get!(image_url).body
    bucket = System.fetch_env!("BUCKET_NAME")

    %{status_code: 200} =
      bucket
      |> ExAws.S3.put_object(file_name, image_binary)
      |> ExAws.request!()

    "#{System.get_env("AWS_PUBLIC_URL")}/#{bucket}/#{file_name}"
  end
end
