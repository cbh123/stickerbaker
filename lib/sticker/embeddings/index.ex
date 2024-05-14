defmodule Sticker.Embeddings.Index do
  @moduledoc """
  Index for embedding search.
  """
  use GenServer
  require Logger
  @me __MODULE__

  def start_link(_opts) do
    GenServer.start_link(@me, [], name: @me)
  end

  def init(_args) do
    index_size = if Application.get_env(:sticker, :env) == :prod, do: 30_000, else: 100

    {:ok, text_index} =
      HNSWLib.Index.new(:l2, 1024, index_size)

    {:ok, image_index} = HNSWLib.Index.new(:l2, 1024, index_size)

    Sticker.Predictions.list_predictions_with_text_embeddings()
    |> Enum.each(fn prediction ->
      HNSWLib.Index.add_items(text_index, Nx.from_binary(prediction.embedding, :f32),
        ids: Nx.tensor([prediction.id])
      )
    end)

    Sticker.Predictions.list_predictions_with_image_embeddings()
    |> Enum.each(fn prediction ->
      HNSWLib.Index.add_items(image_index, Nx.from_binary(prediction.image_embedding, :f32),
        ids: Nx.tensor([prediction.id])
      )
    end)

    Logger.info("Index successfully created")
    {:ok, %{text_index: text_index, image_index: image_index}}
  end

  def search_text(embedding, k) do
    Logger.info("Searching text")
    GenServer.call(@me, {:search_text, embedding, k}, 15_000)
  end

  def search_images(embedding, k) do
    Logger.info("Searching images")
    GenServer.call(@me, {:search_images, embedding, k}, 15_000)
  end

  def get_image_index() do
    GenServer.call(@me, :get_image_index)
  end

  def handle_call(:get_image_index, _from, %{image_index: image_index} = index_dict) do
    {:reply, image_index, index_dict}
  end

  def handle_call({:search_text, embedding, k}, _from, %{text_index: index} = index_dict) do
    {:ok, labels, dists} = HNSWLib.Index.knn_query(index, embedding, k: k)
    {:reply, %{labels: labels, distances: dists}, index_dict}
  end

  def handle_call({:search_images, embedding, k}, _from, %{image_index: index} = index_dict) do
    {:ok, labels, dists} = HNSWLib.Index.knn_query(index, embedding, k: k)
    {:reply, %{labels: labels, distances: dists}, index_dict}
  end

  def terminate(reason, _state) do
    Logger.error("#{__MODULE__} terminated due to #{inspect(reason)}")
  end
end
