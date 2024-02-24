defmodule StickerWeb.ShowLive do
  use StickerWeb, :live_view
  alias Sticker.Predictions

  def mount(%{"id" => id}, _session, socket) do
    prediction = Predictions.get_prediction!(id)
    IO.puts("prediction.sticker_output: #{prediction.sticker_output}")

    {:ok,
     socket
     |> assign(
       prediction: prediction,
       form: to_form(%{"prompt" => prediction.prompt})
     )
     |> SEO.assign(%{
       title: "Check out this AI sticker I made!",
       description: prediction.prompt,
       image: "https://pub-82daccc61df3403caca8ae1ecbca94bf.r2.dev/prediction-103-sticker.png"
     })}
  end

  def handle_event("save", %{"prompt" => prompt}, socket) do
    {:noreply, socket |> push_redirect(to: ~p"/?prompt=#{prompt}")}
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
end
