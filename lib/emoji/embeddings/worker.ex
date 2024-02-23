defmodule Emoji.Embeddings.Worker do
  @moduledoc """
  GenServer for making embeddings out of predictions
  """
  alias Emoji.Predictions
  alias Emoji.Embeddings
  require Logger
  use GenServer

  @embeddings_model "daanelson/imagebind:0383f62e173dc821ec52663ed22a076d9c970549c209666ac3db181618b7a304"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule_creation()
    {:ok, state}
  end

  defp schedule_creation() do
    Process.send_after(self(), :work, 5000)
  end

  defp should_generate_text_embedding?() do
    case Application.get_env(:emoji, :env) do
      :prod -> Predictions.count_predictions_with_text_embeddings() < 100_000
      :dev -> Predictions.count_predictions_with_text_embeddings() < 50
      _ -> false
    end
  end

  defp should_generate_image_embedding?() do
    case Application.get_env(:emoji, :env) do
      :prod -> Predictions.count_predictions_with_image_embeddings() < 100_000
      :dev -> Predictions.count_predictions_with_image_embeddings() < 25
      _ -> false
    end
  end

  defp create_text_embedding(prediction) do
    Logger.info("Creating text embeddings for #{prediction.id}")

    embedding =
      prediction.prompt
      |> Embeddings.clean()
      |> Embeddings.create(@embeddings_model)

    {:ok, prediction} =
      Predictions.update_prediction(prediction, %{
        embedding: embedding,
        embedding_model: @embeddings_model
      })

    prediction
  end

  defp create_image_embedding(%{id: id, no_bg_output: nil}) do
    Logger.info("No url, skipping #{id}")
    nil
  end

  defp create_image_embedding(prediction) do
    Logger.info("Creating image embeddings for #{prediction.id}")

    image_embedding =
      prediction.no_bg_output
      |> Embeddings.create_image(@embeddings_model)

    {:ok, prediction} =
      Predictions.update_prediction(prediction, %{
        image_embedding: image_embedding
      })

    prediction
  end

  def handle_info(:work, state) do
    cond do
      should_generate_image_embedding?() and should_generate_text_embedding?() ->
        Predictions.get_random_prediction_without_text_embeddings() |> create_text_embedding()
        Predictions.get_random_prediction_without_image_embeddings() |> create_image_embedding()

        schedule_creation()

      should_generate_image_embedding?() ->
        Predictions.get_random_prediction_without_image_embeddings() |> create_image_embedding()

        schedule_creation()

      should_generate_text_embedding?() ->
        Predictions.get_random_prediction_without_text_embeddings() |> create_text_embedding()
        schedule_creation()

      true ->
        nil
    end

    {:noreply, state}
  end
end
