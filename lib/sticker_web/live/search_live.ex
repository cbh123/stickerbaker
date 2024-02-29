defmodule StickerWeb.SearchLive do
  use StickerWeb, :live_view

  @num_results 31

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       loading: false,
       num_results: @num_results,
       form: to_form(%{"query" => nil})
     )
     |> stream_configure(:results,
       dom_id: fn {prediction, _distance} ->
         "prediction-#{prediction.id}"
       end
     )
     |> stream(:results, [])}
  end

  @impl true
  def handle_event(
        "search",
        %{"query" => query},
        socket
      ) do
    {:noreply,
     push_patch(socket,
       to: ~p"/experimental-search?query=#{query}"
     )}
  end

  @impl true
  def handle_params(
        %{"query" => query} = params,
        _uri,
        socket
      ) do
    Task.async(fn ->
      Sticker.Embeddings.search_stickers(query, @num_results)
    end)

    {:noreply,
     socket
     |> assign(
       loading: true,
       form: to_form(params)
     )}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, results}, socket) do
    Process.demonitor(ref, [:flush])

    {:noreply,
     socket
     |> assign(loading: false)
     |> stream(:results, results, reset: true)}
  end
end
