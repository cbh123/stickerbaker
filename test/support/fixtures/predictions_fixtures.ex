defmodule Sticker.PredictionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Sticker.Predictions` context.
  """

  @doc """
  Generate a prediction.
  """
  def prediction_fixture(attrs \\ %{}) do
    {:ok, prediction} =
      attrs
      |> Enum.into(%{
        output: "some output",
        prompt: "some prompt",
        uuid: "some uuid"
      })
      |> Sticker.Predictions.create_prediction()

    prediction
  end
end
