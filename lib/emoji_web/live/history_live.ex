defmodule EmojiWeb.HistoryLive do
  use EmojiWeb, :live_view
  alias Emoji.Predictions

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(local_user_id: nil) |> assign(results: [])}
  end

  def handle_event("assign-user-id", %{"userId" => user_id}, socket) do
    {:noreply,
     socket
     |> assign(local_user_id: user_id)
     |> stream(:predictions, Predictions.list_user_predictions(user_id))}
  end
end
