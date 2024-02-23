defmodule EmojiWeb.HomeLive do
  use EmojiWeb, :live_view
  alias Emoji.Predictions

  @fail_image "https://github.com/replicate/zoo/assets/14149230/39c124db-a793-4ca9-a9b4-706fe18984ad"

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(form: to_form(%{"prompt" => ""}))
     |> assign(local_user_id: nil)
     |> assign(remove_bg: false)
     |> stream(:my_predictions, [])
     |> stream(:featured_predictions, Predictions.list_featured_predictions())
     |> stream(:latest_predictions, Predictions.list_latest_safe_predictions(9))}
  end

  def handle_event("thumbs-up", %{"id" => id}, socket) do
    prediction = Predictions.get_prediction!(id)

    {:ok, _prediction} =
      Predictions.update_prediction(prediction, %{
        score: prediction.score + 1,
        count_votes: prediction.count_votes + 1
      })

    {:noreply, socket |> put_flash(:info, "Thanks for your rating!")}
  end

  def handle_event("thumbs-down", %{"id" => id}, socket) do
    prediction = Predictions.get_prediction!(id)

    {:ok, _prediction} =
      Predictions.update_prediction(prediction, %{
        score: prediction.score - 1,
        count_votes: prediction.count_votes + 1
      })

    {:noreply, socket |> put_flash(:info, "Thanks for your rating!")}
  end

  def handle_event("toggle-bg", _, socket) do
    {:noreply, socket |> assign(show_bg: !socket.assigns.show_bg)}
  end

  def handle_event("validate", %{"prompt" => _prompt}, socket) do
    {:noreply, socket}
  end

  def handle_event("assign-user-id", %{"userId" => user_id}, socket) do
    {:noreply, socket |> assign(local_user_id: user_id)}
  end

  def handle_event("save", %{"prompt" => prompt, "submit" => "search"}, socket) do
    {:noreply, socket |> push_navigate(to: ~p"/experimental-search?query=#{prompt}")}
  end

  def handle_event("save", %{"prompt" => prompt, "submit" => "generate"}, socket) do
    {:ok, prediction} =
      Predictions.create_prediction(%{
        prompt: prompt,
        local_user_id: socket.assigns.local_user_id
      })

    start_task(fn -> {:scored, prediction, moderate(prediction.prompt)} end)

    {:noreply,
     socket
     |> stream_insert(:my_predictions, prediction, at: 0)}
  end

  def handle_info({:scored, prediction, {moderator, rating}}, socket) do
    {:ok, prediction} =
      Predictions.update_prediction(prediction, %{
        moderation_score: String.to_integer(rating),
        moderator: moderator
      })

    if String.to_integer(rating) >= 9 do
      {:ok, prediction} = Predictions.update_prediction(prediction, %{emoji_output: @fail_image})

      {:noreply,
       socket
       |> put_flash(
         :error,
         "Uh oh, this doesn't seem appropriate. Submit an issue on GitHub if you think the AI is wrong. Rating: #{10 - String.to_integer(rating)}/10"
       )
       |> stream_insert(:my_predictions, prediction)}
    else
      start_task(fn -> {:image_generated, prediction, gen_image(prediction.prompt)} end)

      {:noreply,
       socket
       |> put_flash(:info, "AI generated safety rating: #{10 - String.to_integer(rating)}/10")}
    end
  end

  def handle_info(
        {:image_generated, prediction, {:ok, %{"output" => ""} = r8_prediction}},
        socket
      ) do
    {:ok, prediction} =
      Predictions.update_prediction(prediction, %{
        emoji_output: @fail_image,
        uuid: r8_prediction.id
      })

    {:noreply,
     socket
     |> put_flash(:error, "Uh oh, image generation failed. Likely NSFW input. Try again!")
     |> stream_insert(:my_predictions, prediction)}
  end

  def handle_info({:image_generated, prediction, {:ok, r8_prediction}}, socket) do
    r2_url = save_r2("prediction-#{prediction.id}-emoji", r8_prediction.output |> List.last())

    {:ok, prediction} =
      Predictions.update_prediction(prediction, %{
        emoji_output: r2_url,
        uuid: r8_prediction.id
      })

    {:noreply,
     socket
     |> stream_insert(:my_predictions, prediction)
     |> put_flash(:info, "Sticker generated! Click it to download.")}
  end

  defp moderate(prompt) do
    adjusted_prompt = "[PROMPT] #{prompt} [/PROMPT] [SAFETY_RANKING]"

    moderator =
      "fofr/prompt-classifier:1ffac777bf2c1f5a4a5073faf389fefe59a8b9326b3ca329e9d576cce658a00f"

    {moderator,
     moderator
     |> Replicate.run(
       prompt: adjusted_prompt,
       max_new_tokens: 128,
       temperature: 0.2,
       top_p: 0.9,
       top_k: 50,
       stop_sequences: "[/SAFETY_RANKING]"
     )
     |> Enum.join()
     |> String.trim()}
  end

  defp gen_image(prompt) do
    {:ok, model} = Replicate.Models.get("fofr/sticker-maker")
    version = Replicate.Models.get_latest_version!(model)

    {:ok, prediction} =
      Replicate.Predictions.create(version,
        prompt: prompt,
        width: 512,
        height: 512,
        num_inference_steps: 20,
        negative_prompt: "racist, xenophobic, antisemitic, islamophobic, bigoted",
        upscale: false
      )
      |> wait()
      |> IO.inspect(label: "pred")

    {:ok, prediction}
  end

  defp wait({:ok, prediction}), do: Replicate.Predictions.wait(prediction)

  defp start_task(fun) do
    pid = self()

    Task.start_link(fn ->
      result = fun.()
      send(pid, result)
    end)
  end

  def save_r2(name, image_url) do
    image_binary = Req.get!(image_url).body
    file_name = "#{name}.png"
    bucket = System.get_env("CLOUDFLARE_BUCKET")

    %{status_code: 200} =
      ExAws.S3.put_object(bucket, file_name, image_binary)
      |> ExAws.request!()

    "#{System.get_env("CLOUDFLARE_PUBLIC_URL")}/#{file_name}"
  end

  def send_telegram_message(prompt, image, id, score) do
    {:ok, token} = System.fetch_env("TELEGRAM_BOT_TOKEN")
    {:ok, chat_id} = System.fetch_env("TELEGRAM_CHAT_ID")

    url = "https://api.telegram.org/bot#{token}/sendMessage"
    headers = ["Content-Type": "application/json"]

    body =
      Jason.encode!(%{
        chat_id: chat_id,
        text:
          "prompt: #{prompt}, image: #{image}, url: https://sticker.fly.dev/emoji/#{id}, moderation score: #{score}"
      })

    HTTPoison.post(url, body, headers)
  end
end
