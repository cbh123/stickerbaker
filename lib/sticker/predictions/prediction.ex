defmodule Sticker.Predictions.Prediction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "predictions" do
    field :no_bg_output, :string
    field :sticker_output, :string
    field :prompt, :string
    field :uuid, :string
    field :score, :integer, default: 0
    field :count_votes, :integer, default: 0
    field :is_featured, Ecto.Enum, values: [true, false]
    field :local_user_id, :string
    field :moderation_score, :integer
    field :moderator, :string
    field :embedding, :binary
    field :image_embedding, :binary
    field :embedding_model, :string
    field :flag, Ecto.Enum, values: [true, false]

    field :status, Ecto.Enum,
      values: [:starting, :processing, :succeeded, :failed, :canceled, :moderation_succeeded]

    field :autoplay_time, :utc_datetime
    field :model, :string

    timestamps()
  end

  @doc false
  def changeset(prediction, attrs) do
    prediction
    |> cast(attrs, [
      :uuid,
      :prompt,
      :no_bg_output,
      :sticker_output,
      :score,
      :count_votes,
      :is_featured,
      :local_user_id,
      :moderation_score,
      :moderator,
      :embedding,
      :image_embedding,
      :embedding_model,
      :status,
      :autoplay_time,
      :model
    ])
    |> validate_required([:prompt])
  end
end
