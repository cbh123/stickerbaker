defmodule StickerWeb.AdminLive do
  use StickerWeb, :live_view
  alias Phoenix.PubSub
  alias Sticker.Predictions

  def mount(_params, session, socket) do
    page = 0
    per_page = 20
    max_pages = Predictions.number_safe_predictions() / per_page

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Sticker.PubSub, "prediction-firehose")
    end

    {:ok,
     socket
     |> assign(local_user_id: session["local_user_id"])
     |> assign(page: page)
     |> assign(per_page: per_page)
     |> assign(max_pages: max_pages)
     |> stream(:latest_predictions, Predictions.list_latest_safe_predictions(page, per_page))}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    next_page = assigns.page + 1

    latest_predictions =
      Predictions.list_latest_safe_predictions(assigns.page, socket.assigns.per_page)

    {:noreply,
     socket
     |> assign(page: next_page)
     |> stream(:latest_predictions, latest_predictions)}
  end

  def handle_event("toggle-allow", %{"id" => id}, socket) do
    prediction = Predictions.get_prediction!(id)

    {:ok, prediction} =
      Predictions.update_prediction(prediction, %{"is_featured" => !prediction.is_featured})

    {:noreply, socket |> stream_insert(:latest_predictions, prediction)}
  end

  def handle_event("validate", %{"prompt" => _prompt}, socket) do
    {:noreply, socket}
  end

  def handle_event("assign-user-id", %{"userId" => user_id}, socket) do
    PubSub.subscribe(Sticker.PubSub, "user:#{user_id}")

    {:noreply, socket |> assign(local_user_id: user_id)}
  end

  def handle_info({:new_prediction, prediction}, socket) do
    {:noreply, socket |> stream_insert(:latest_predictions, prediction, at: 0)}
  end
end
