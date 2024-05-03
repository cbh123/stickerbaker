defmodule StickerWeb.HomeLive do
  use StickerWeb, :live_view
  alias Phoenix.PubSub
  alias Sticker.Predictions

  @accepted ~w(.jpg .jpeg .png)

  def mount(_params, session, socket) do
    page = 0
    per_page = 20
    max_pages = Predictions.number_moderated_predictions() / per_page

    loading_predictions =
      Predictions.list_loading_predictions(session["local_user_id"])

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Sticker.PubSub, "safe-prediction-firehose")
    end

    {:ok,
     socket
     |> assign(form: to_form(%{"prompt" => ""}))
     |> assign(local_user_id: session["local_user_id"])
     |> assign(page: page)
     |> assign(per_page: per_page)
     |> assign(max_pages: max_pages)
     |> stream(:my_predictions, loading_predictions)
     |> stream(:latest_predictions, Predictions.list_latest_safe_predictions(page, per_page))
     |> allow_upload(:image, accept: @accepted)}
  end

  def handle_params(%{"prompt" => prompt}, _, socket) do
    {:noreply, socket |> assign(form: to_form(%{"prompt" => prompt}))}
  end

  def handle_params(_params, _, socket) do
    {:noreply, socket}
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

  def handle_event("validate", %{"prompt" => prompt}, socket) do
    {:noreply, socket |> assign(form: to_form(%{"prompt" => prompt}))}
  end

  def handle_event("assign-user-id", %{"userId" => user_id}, socket) do
    PubSub.subscribe(Sticker.PubSub, "user:#{user_id}")

    {:noreply, socket |> assign(local_user_id: user_id)}
  end

  def handle_event("save", %{"prompt" => prompt}, socket) do
    user_id = socket.assigns.local_user_id

    {:ok, prediction} =
      Predictions.create_prediction(%{
        prompt: prompt,
        local_user_id: user_id
      })

    # Check if there are any uploaded images. If there are,
    # we'll do face to sticker. Otherwise we'll kick off normal sticker prediction
    if Enum.any?(socket.assigns.uploads.image.entries, & &1.done?) do
      consume_uploaded_entries(socket, :image, fn %{path: path}, entry ->
        uri =
          path
          |> File.read!()
          |> Base.encode64()
          |> Sticker.Utils.base64_to_data_uri(entry.client_type)

        {:ok, _prediction} =
          Predictions.update_prediction(prediction, %{
            model: "face-to-sticker"
          })

        send(self(), {:kick_off_face_to_sticker, prediction, uri})

        {:ok, path}
      end)
    else
      send(self(), {:kick_off_sticker, prediction})
    end

    {
      :noreply,
      socket
      |> assign(form: to_form(%{"prompt" => ""}))
      |> stream_insert(:my_predictions, prediction, at: 0)
    }
  end

  def handle_info({:new_prediction, prediction}, socket) do
    {:noreply, socket |> stream_insert(:latest_predictions, prediction, at: 0)}
  end

  def handle_info({:kick_off_sticker, prediction}, socket) do
    Predictions.moderate(prediction.prompt, prediction.local_user_id, prediction.id)
    {:noreply, socket}
  end

  def handle_info({:kick_off_face_to_sticker, prediction, image_uri}, socket) do
    Predictions.gen_face_to_sticker(
      prediction.prompt,
      image_uri,
      prediction.local_user_id,
      prediction.id
    )

    {:noreply, socket}
  end

  def handle_info({:moderation_complete, prediction}, socket) do
    if prediction.moderation_score < 9 do
      {:noreply,
       socket
       |> put_flash(:info, "AI generated safety rating:  #{10 - prediction.moderation_score}/10")
       |> stream_insert(:my_predictions, prediction)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "AI generated safety rating:  #{10 - prediction.moderation_score}/10")}
    end
  end

  def handle_info({:prediction_started, prediction}, socket) do
    {:noreply,
     socket
     |> stream_insert(:my_predictions, prediction, at: 0)}
  end

  def handle_info({:prediction_loading, prediction}, socket) do
    {:noreply,
     socket
     |> stream_insert(:my_predictions, prediction, at: 0)}
  end

  def handle_info({:prediction_failed, _prediction}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Uh oh, image generation failed. Likely NSFW input. Try again!")}
  end

  def handle_info({:prediction_completed, prediction}, socket) do
    {:noreply,
     socket
     |> stream_insert(:my_predictions, prediction)
     |> put_flash(:info, "Sticker generated! Click it to download.")}
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "Sorry, we only accept #{@accepted}"
end
