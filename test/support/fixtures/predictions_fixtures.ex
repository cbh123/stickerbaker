defmodule Emoji.PredictionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Emoji.Predictions` context.
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
      |> Emoji.Predictions.create_prediction()

    prediction
  end
end
