defmodule Emoji.Predictions do
  @moduledoc """
  The Predictions context.
  """

  import Ecto.Query, warn: false
  alias Emoji.Repo

  alias Emoji.Predictions.Prediction

  def get_predictions(ids) do
    from(p in Prediction, where: p.id in ^ids and not is_nil(p.emoji_output)) |> Repo.all()
  end

  def count_predictions_with_text_embeddings() do
    Repo.aggregate(
      from(p in Prediction, where: not p.embedding |> is_nil()),
      :count
    )
  end

  def count_predictions_with_image_embeddings() do
    Repo.aggregate(
      from(p in Prediction, where: not p.image_embedding |> is_nil()),
      :count
    )
  end

  def get_random_prediction_without_text_embeddings() do
    from(p in Prediction,
      where: is_nil(p.embedding) and not is_nil(p.emoji_output) and p.score != 10,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> Repo.one!()
  end

  def get_random_prediction_without_image_embeddings() do
    from(p in Prediction,
      where: is_nil(p.image_embedding) and not is_nil(p.emoji_output) and p.score != 10,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> Repo.one!()
  end

  @doc """
  Returns the list of predictions.

  ## Examples

      iex> list_predictions()
      [%Prediction{}, ...]

  """
  def list_predictions do
    Repo.all(Prediction)
  end

  def list_predictions_with_text_embeddings do
    Repo.all(from p in Prediction, where: not is_nil(p.embedding) and not is_nil(p.emoji_output))
  end

  def list_predictions_with_image_embeddings do
    Repo.all(
      from p in Prediction, where: not is_nil(p.image_embedding) and not is_nil(p.emoji_output)
    )
  end

  def list_latest_safe_predictions(limit) do
    Repo.all(
      from p in Prediction,
        where: not is_nil(p.no_bg_output) and p.moderation_score <= 5,
        order_by: [desc: p.inserted_at],
        limit: ^limit
    )
  end

  def list_user_predictions(user_id) do
    Repo.all(
      from p in Prediction,
        where: p.local_user_id == ^user_id,
        order_by: [desc: p.inserted_at],
        where: not is_nil(p.no_bg_output)
    )
  end

  def list_finished_predictions() do
    Repo.all(
      from p in Prediction,
        where: not is_nil(p.no_bg_output) and p.score > 3 and p.count_votes > 5,
        order_by: fragment("RANDOM()"),
        limit: 16
    )
  end

  def list_featured_predictions() do
    Repo.all(
      from p in Prediction,
        where:
          p.is_featured == true or
            (not is_nil(p.no_bg_output) and p.score > 3 and p.count_votes > 5),
        order_by: fragment("RANDOM()"),
        limit: 16
    )
  end

  @doc """
  Gets a single prediction.

  Raises `Ecto.NoResultsError` if the Prediction does not exist.

  ## Examples

      iex> get_prediction!(123)
      %Prediction{}

      iex> get_prediction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_prediction!(id), do: Repo.get!(Prediction, id)

  @doc """
  Creates a prediction.

  ## Examples

      iex> create_prediction(%{field: value})
      {:ok, %Prediction{}}

      iex> create_prediction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_prediction(attrs \\ %{}) do
    %Prediction{}
    |> Prediction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a prediction.

  ## Examples

      iex> update_prediction(prediction, %{field: new_value})
      {:ok, %Prediction{}}

      iex> update_prediction(prediction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_prediction(%Prediction{} = prediction, attrs) do
    prediction
    |> Prediction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a prediction.

  ## Examples

      iex> delete_prediction(prediction)
      {:ok, %Prediction{}}

      iex> delete_prediction(prediction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_prediction(%Prediction{} = prediction) do
    Repo.delete(prediction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking prediction changes.

  ## Examples

      iex> change_prediction(prediction)
      %Ecto.Changeset{data: %Prediction{}}

  """
  def change_prediction(%Prediction{} = prediction, attrs \\ %{}) do
    Prediction.changeset(prediction, attrs)
  end
end
