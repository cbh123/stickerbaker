defmodule StickerWeb.ShowLive do
  use StickerWeb, :live_view
  alias Sticker.Predictions

  @num_results 21

  def mount(%{"id" => id}, _session, socket) do
    prediction = Predictions.get_prediction!(id)

    {:ok,
     socket
     |> assign(
       prediction: prediction,
       given_feedback: false,
       form: to_form(%{"prompt" => prediction.prompt})
     )
     |> assign_async(
       :similar_stickers,
       fn ->
         {:ok,
          %{similar_stickers: Sticker.Embeddings.search_stickers(prediction.prompt, @num_results)}}
       end
     ), temporary_assigns: [{SEO.key(), nil}]}
  end

  def handle_params(_params, _url, socket) do
    {:noreply,
     SEO.assign(socket, %{
       title: "I made an AI sticker of #{socket.assigns.prediction.prompt}",
       description: socket.assigns.prediction.prompt,
       image: socket.assigns.prediction.sticker_output
     })}
  end

  def handle_event("save", %{"prompt" => prompt}, socket) do
    {:noreply, socket |> push_redirect(to: ~p"/?prompt=#{prompt}")}
  end

  def handle_event("click-event", %{"event" => event}, socket) do
    {:ok, _event} = Predictions.log_event(event)
    {:noreply, socket}
  end

  def handle_event("flag", %{"id" => id}, socket) do
    prediction = Predictions.get_prediction!(id)

    {:ok, _prediction} =
      Predictions.update_prediction(prediction, %{
        flag: true
      })

    {:noreply,
     socket
     |> put_flash(
       :info,
       "Your wish is granted. This sticker is reported."
     )}
  end

  def handle_event("thumbs-up", %{"id" => id}, socket) do
    prediction = Predictions.get_prediction!(id)

    {:ok, _prediction} =
      Predictions.update_prediction(prediction, %{
        score: prediction.score + 1,
        count_votes: prediction.count_votes + 1
      })

    {:noreply,
     socket |> assign(given_feedback: true) |> put_flash(:info, "Thanks for your rating!")}
  end

  def handle_event("thumbs-down", %{"id" => id}, socket) do
    prediction = Predictions.get_prediction!(id)

    {:ok, _prediction} =
      Predictions.update_prediction(prediction, %{
        score: prediction.score - 1,
        count_votes: prediction.count_votes + 1
      })

    {:noreply,
     socket |> assign(given_feedback: true) |> put_flash(:info, "Thanks for your rating!")}
  end
end
