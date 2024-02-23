defmodule EmojiWeb.SearchLive do
  use EmojiWeb, :live_view

  @num_results 21

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       loading: false,
       num_results: @num_results,
       form: to_form(%{"query" => nil, "search_via_images" => false})
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
        %{"query" => query, "search_via_images" => search_via_images},
        socket
      ) do
    {:noreply,
     push_patch(socket,
       to: ~p"/experimental-search?query=#{query}&search_via_images=#{search_via_images}"
     )}
  end

  @impl true
  def handle_params(
        %{
          "query" => query,
          "search_via_images" => search_via_images,
          "num_results" => num_results
        } = params,
        _uri,
        socket
      ) do
    Task.async(fn ->
      Emoji.Embeddings.search_emojis(query, num_results, search_via_images == "true")
    end)

    {:noreply,
     socket
     |> assign(
       loading: true,
       form: to_form(params)
     )}
  end

  @impl true
  def handle_params(
        %{"query" => query, "search_via_images" => search_via_images} = params,
        _uri,
        socket
      ) do
    Task.async(fn ->
      Emoji.Embeddings.search_emojis(query, @num_results, search_via_images == "true")
    end)

    {:noreply,
     socket
     |> assign(
       loading: true,
       form: to_form(params)
     )}
  end

  @impl true
  def handle_params(%{"query" => query} = params, _uri, socket) do
    Task.async(fn -> Emoji.Embeddings.search_emojis(query, @num_results, false) end)

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
