defmodule StickerWeb.ReplicateWebhookController do
  use StickerWeb, :controller
  alias Sticker.Predictions
  require Logger

  @annoying_users ["lt3hjkan30umvl86oz2", "lt3ihfm35457xftgd3r", "lt3ihohmy96n9ofb5m"]

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
    rating = Sticker.Utils.parse_prompt_classifier_output(output)

    if user_id in @annoying_users do
      broadcast(user_id, {:moderation_failed, "Something went wrong...try again?"})
    else
      case status do
        "succeeded" ->
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
          if rating <= 5 do
            gen_sticker(prompt)
          else
            broadcast(user_id, {:moderation_failed, "AI generated safety rating:  {3}/10")})
          end

        "failed" ->
          broadcast(user_id, {:moderation_failed, "Something went wrong...try again?"})

        status ->
          IO.inspect("status is... #{status}")
      end
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
          "model" => _model,
          "prediction_id" => prediction_id
        }
      ) do
    prediction = prediction_id |> Predictions.get_prediction!()

    case status do
      "succeeded" ->
        r2_url =
          Sticker.Utils.save_r2(
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

        Phoenix.PubSub.broadcast(
          Sticker.PubSub,
          "prediction-firehose",
          {:new_prediction, prediction}
        )

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

  # catch-all handle webhook
  def handle_webhook(conn, _params) do
    Logger.warning("uncaught webhook")

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
  end

  defp broadcast(user_id, message),
    do: Phoenix.PubSub.broadcast(Sticker.PubSub, "user:#{user_id}", message)
end
