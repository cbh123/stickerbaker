defmodule StickerWeb.SearchLive do
  use StickerWeb, :live_view

  @num_results 50

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       loading: false,
       num_results: @num_results,
       number_searchable_stickers: Sticker.Predictions.count_predictions_with_text_embeddings(),
       elapsed_time: nil,
       form: to_form(%{"query" => nil})
     )
     |> stream_configure(:results,
       dom_id: fn {prediction, _distance} ->
         "prediction-#{prediction.id}"
       end
     )
     |> stream(:results, [])
     |> SEO.assign(%{
       title: "StickerSearch",
       description: "Search for AI generated stickers",
       image: "/images/search.png"
     })}
  end

  @impl true
  def handle_event(
        "search",
        %{"query" => query},
        socket
      ) do
    {:noreply,
     push_patch(socket,
       to: ~p"/search?query=#{query}"
     )}
  end

  @impl true
  def handle_params(%{"query" => query} = params, _uri, socket) do
    start_time = System.monotonic_time()

    Task.async(fn ->
      Sticker.Embeddings.search_stickers(query, @num_results)
    end)

    {:noreply,
     socket
     |> assign(
       loading: true,
       start_time: start_time,
       form: to_form(params)
     )}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, results}, socket) do
    Process.demonitor(ref, [:flush])
    end_time = System.monotonic_time()

    elapsed_time =
      System.convert_time_unit(end_time - socket.assigns.start_time, :native, :millisecond)

    {:noreply,
     socket
     |> assign(loading: false, elapsed_time: elapsed_time)
     |> stream(:results, results, reset: true)}
  end
end
