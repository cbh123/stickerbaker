# StickerBaker

<blockquote class="twitter-tweet" data-media-max-width="560"><p lang="en" dir="ltr">Announcing StickerBaker!<br><br>Make stickers with AI. Powered by <a href="https://twitter.com/replicate?ref_src=twsrc%5Etfw">@replicate</a> and <a href="https://twitter.com/flydotio?ref_src=twsrc%5Etfw">@flydotio</a>, and 100% open-source.<a href="https://t.co/8vucCsHtAd">https://t.co/8vucCsHtAd</a> <a href="https://t.co/tBhDyGrOx0">pic.twitter.com/tBhDyGrOx0</a></p>&mdash; Charlie Holtz (@charliebholtz) <a href="https://twitter.com/charliebholtz/status/1762232726361633018?ref_src=twsrc%5Etfw">February 26, 2024</a></blockquote>

## How it works

Enter a prompt and generating a sticker using https://replicate.com/fofr/sticker-maker.

The home page is rendered in `lib/sticker_web/home_live.ex`. When the prompt form is submitted, this handle_event gets called:

```elixir
  def handle_event("save", %{"prompt" => prompt}, socket) do
    user_id = socket.assigns.local_user_id

    {:ok, prediction} =
      Predictions.create_prediction(%{
        prompt: prompt,
        local_user_id: user_id
      })

    send(self(), {:kick_off, prediction})

    {:noreply,
     socket
     |> assign(form: to_form(%{"prompt" => ""}))
     |> stream_insert(:my_predictions, prediction, at: 0)}
  end
```

This sends a `:kick_off` message to the LiveView (so there is no lag) which calls `Predictions.moderate/3` in `lib/sticker/predictions.ex`:

```elixir
  @doc """
  Moderates a prediction.
  The logic in replicate_webhook_controller.ex handles
  the webhook. Once the moderation is complete, the webhook controller automatically
  called gen_image.
  """
  def moderate(prompt, user_id, prediction_id) do
    "fofr/prompt-classifier"
    |> Replicate.Models.get!()
    |> Replicate.Models.get_latest_version!()
    |> Replicate.Predictions.create(
      %{
        prompt: "[PROMPT] #{prompt} [/PROMPT] [SAFETY_RANKING]",
        max_new_tokens: 128,
        temperature: 0.2,
        top_p: 0.9,
        top_k: 50,
        stop_sequences: "[/SAFETY_RANKING]"
      },
      "#{Sticker.Utils.get_host()}/webhooks/replicate?user_id=#{user_id}&prediction_id=#{prediction_id}"
    )
  end
```

We pass a webhook to [Replicate](https://replicate.com). All the logic for the webhook lives in `lib/sticker_web/controllers/replicate_webhook_controller.ex`. The nice thing about this webhook is that we can refresh the page or disconnect and [Replicate](https://replicate.com) still handles the prediction queue for us. Once the prediction is ready,
we upload it to Tigris (Replicate doesn't save our data for us) and then the sticker gets broadcast back to our `home_live.ex`.

StickerBaker runs on:

- [Replicate](https://replicate.com/fofr/sticker-maker?utm_source=project&utm_campaign=stickerbaker) to generate the stickers
- [Fly.io](https://fly.io) for infrastructure
- [Tigris](https://www.tigrisdata.com) for image hosting

## Dev

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
- Add a .env file with REPLICATE_API_TOKEN set to your [Replicate](https://replicate.com/) token

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
