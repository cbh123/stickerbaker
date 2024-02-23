defmodule EmojiWeb.SlackController do
  use EmojiWeb, :controller

  @preprompt "A TOK emoji of a "

  def command(conn, params) do
    # Modify based on the structure of your response
    {:ok, body} = send_ephemeral_message("⏳ Generating AI #{params["text"]}...", params)

    Task.async(fn -> process_request(params, body["message"]["ts"]) end)

    send_resp(conn, 200, "")
  end

  defp process_request(params, message_ts) do
    {:ok, prediction} = gen_image(params["text"])

    case prediction.output do
      [image] ->
        {:ok, _params} =
          send_ephemeral_message("🖌️ Removing background...", params)

        image = remove_bg(image)

        {:ok, _params} =
          send_ephemeral_message("🎉 Done!", params)

        send_completed_message(params["text"], image, params)

      nil ->
        send_ephemeral_message("Failed :(", params)
    end
  end

  defp update_slack_message(channel_id, timestamp, text) do
    url = "https://slack.com/api/chat.update"

    headers = [
      {"Authorization", "Bearer #{System.fetch_env!("SLACK_API_TOKEN")}"},
      {"Content-type", "application/json"}
    ]

    payload = %{
      "channel" => channel_id,
      # This ensures the correct message is updated
      "ts" => timestamp,
      "text" => text
    }

    HTTPoison.post(url, Jason.encode!(payload), headers)
    |> IO.inspect(label: "update_slack_message")
  end

  defp send_completed_message(text, image, %{"channel_id" => channel_id} = params) do
    url = "https://slack.com/api/chat.postMessage"

    headers = [
      {"Authorization", "Bearer #{System.fetch_env!("SLACK_API_TOKEN")}"},
      {"Content-type", "application/json"}
    ]

    payload = %{
      "channel" => channel_id,
      # This ensures the correct message is updated
      "text" => text,
      "blocks" => [
        %{
          type: "section",
          text: %{
            type: "mrkdwn",
            text:
              "AI #{text} by @#{params["user_name"]} and <https://replicate.com/fofr/sdxl-emoji|fofr/sdxl-emoji>"
          }
        },
        %{
          type: "image",
          title: %{
            type: "plain_text",
            text: text
          },
          block_id: "image4",
          image_url: image,
          alt_text: text
        }
      ]
    }

    {:ok, %{status_code: 200} = response} =
      HTTPoison.post(url, Jason.encode!(payload), headers) |> IO.inspect(label: "completed")

    {:ok, Jason.decode!(response.body)}
  end

  defp send_ephemeral_message(message, %{"channel_id" => channel_id, "user_id" => user_id}) do
    url = "https://slack.com/api/chat.postEphemeral"

    headers = [
      {"Authorization", "Bearer #{System.fetch_env!("SLACK_API_TOKEN")}"},
      {"Content-type", "application/json"}
    ]

    payload = %{
      # You can also get this from the initial request params
      "channel" => channel_id,
      "user" => user_id,
      "text" => message
    }

    {:ok, %{status_code: 200} = response} = HTTPoison.post(url, Jason.encode!(payload), headers)
    {:ok, Jason.decode!(response.body)}
  end

  defp gen_image(prompt) do
    styled_prompt =
      (@preprompt <> String.trim_trailing(String.downcase(prompt)))
      |> String.replace("emoji of a a ", "emoji of a ")
      |> String.replace("emoji of a an ", "emoji of an ")

    {:ok, deployment} = Replicate.Deployments.get("cbh123/sdxl-emoji")

    {:ok, prediction} =
      Replicate.Deployments.create_prediction(deployment,
        prompt: styled_prompt,
        width: 512,
        height: 512,
        num_inference_steps: 30,
        negative_prompt: "racist, xenophobic, antisemitic, islamophobic, bigoted"
      )
      |> wait()

    {:ok, prediction}
  end

  defp wait({:ok, prediction}), do: Replicate.Predictions.wait(prediction)

  defp remove_bg(url) do
    "cjwbw/rembg:fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003"
    |> Replicate.run(image: url)
  end
end
