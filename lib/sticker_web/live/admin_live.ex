defmodule StickerWeb.AdminLive do
  use StickerWeb, :live_view
  alias Phoenix.PubSub
  alias Sticker.Predictions

  def mount(_params, session, socket) do
    page = 0
    per_page = 50
    max_pages = Predictions.number_predictions() / per_page
    autoplay = Sticker.Autoplay.get_state()
    total_unmoderated_predictions = Predictions.number_unmoderated_predictions()
    total_moderated_predictions = Predictions.number_moderated_predictions()

    {:ok,
     socket
     |> assign(autoplay: autoplay)
     |> assign(total_unmoderated_predictions: total_unmoderated_predictions)
     |> assign(total_moderated_predictions: total_moderated_predictions)
     |> assign(show_all: false)
     |> assign(local_user_id: session["local_user_id"])
     |> assign(page: page)
     |> assign(per_page: per_page)
     |> assign(max_pages: max_pages)
     |> assign(number_predictions: Predictions.number_predictions())}
  end

  def handle_params(%{"all" => "true"}, _, socket) do
    {:noreply,
     socket
     |> assign(show_all: true)
     |> stream(
       :latest_predictions,
       list_latest_predictions(socket.assigns.page, socket.assigns.per_page)
     )}
  end

  def handle_params(_params, _, socket) do
    {:noreply,
     socket
     |> stream(
       :latest_predictions,
       list_latest_predictions_no_moderation(socket.assigns.page, socket.assigns.per_page)
     )}
  end

  defp list_latest_predictions_no_moderation(page, per_page) do
    Predictions.list_latest_predictions_no_moderation(page, per_page)
  end

  defp list_latest_predictions(page, per_page) do
    Predictions.list_latest_predictions(page, per_page)
  end

  def handle_event(
        "swipe_prediction",
        %{"prediction" => prediction_data, "action" => action},
        socket
      ) do
    IO.puts("swipe_prediction: #{action} #{prediction_data}")

    prediction = Predictions.get_prediction!(prediction_data)

    {:ok, _prediction} =
      Predictions.update_prediction(prediction, %{"is_featured" => action == "allow"})

    if action == "allow" do
      Phoenix.PubSub.broadcast(
        Sticker.PubSub,
        "safe-prediction-firehose",
        {:new_prediction, prediction}
      )
    end

    {:noreply, socket}
  end

  def handle_event("toggle-autoplay", _params, socket) do
    if socket.assigns.autoplay do
      Sticker.Autoplay.deactivate()
    else
      Sticker.Autoplay.activate()
    end

    # Fetch the new state to ensure consistency
    new_state = Sticker.Autoplay.get_state()

    # Update the socket with the new state and re-render
    {:noreply,
     assign(socket, autoplay: new_state)
     |> put_flash(:info, "Autoplay should be #{new_state}. Check the home page to confirm.")}
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    next_page = assigns.page + 1

    latest_predictions =
      list_latest_predictions_no_moderation(assigns.page, socket.assigns.per_page)

    {:noreply,
     socket
     |> assign(page: next_page)
     |> stream(:latest_predictions, latest_predictions)}
  end

  def handle_event("allow", %{"id" => id}, socket) do
    prediction = Predictions.get_prediction!(id)

    set_featured_to = if prediction.is_featured == true, do: nil, else: true

    {:ok, prediction} =
      Predictions.update_prediction(prediction, %{"is_featured" => set_featured_to})

    Phoenix.PubSub.broadcast(
      Sticker.PubSub,
      "safe-prediction-firehose",
      {:new_prediction, prediction}
    )

    {:noreply, socket |> stream_insert(:latest_predictions, prediction)}
  end

  def handle_event("unallow", %{"id" => id}, socket) do
    prediction = Predictions.get_prediction!(id)

    set_featured_to = if prediction.is_featured == false, do: nil, else: false

    {:ok, prediction} =
      Predictions.update_prediction(prediction, %{"is_featured" => set_featured_to})

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
