defmodule StickerWeb.ShowLive do
  use StickerWeb, :live_view
  alias Sticker.Predictions
  alias Sticker.Predictions.Prediction

  def mount(%{"id" => id}, _session, socket) do
    prediction = Predictions.get_prediction!(id)

    {:ok,
     socket |> assign(prediction: prediction, form: to_form(%{"prompt" => prediction.prompt}))}
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
