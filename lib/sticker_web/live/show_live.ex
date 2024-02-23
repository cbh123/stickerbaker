defmodule StickerWeb.ShowLive do
  use StickerWeb, :live_view
  alias Sticker.Predictions
  alias Sticker.Predictions.Prediction

  def mount(%{"id" => id}, _session, socket) do
    prediction = Predictions.get_prediction!(id)
    {:ok, socket |> assign(prediction: prediction) |> assign(show_bg: false)}
  end

  def handle_event("toggle-bg", _, socket) do
    {:noreply, socket |> assign(show_bg: !socket.assigns.show_bg)}
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

  def render_image(%Prediction{no_bg_output: nil, sticker_output: nil}, _show_bg), do: nil

  def render_image(%Prediction{no_bg_output: nil, sticker_output: sticker_output}, _show_bg),
    do: sticker_output

  def render_image(%Prediction{no_bg_output: no_bg_output, sticker_output: nil}, _show_bg),
    do: no_bg_output

  def render_image(%Prediction{no_bg_output: _no_bg_output, sticker_output: sticker_output}, true),
    do: sticker_output

  def render_image(%Prediction{no_bg_output: no_bg_output, sticker_output: _sticker_output}, false),
    do: no_bg_output

  defp human_name(name) do
    dasherize(name)
  end

  defp dasherize(name) do
    name
    |> String.replace("A TOK sticker of a ", "")
    |> String.replace("A TOK sticker of an ", "")
    |> String.split(" ")
    |> Enum.join("-")
    |> String.replace("--", "-")
  end
end
