defmodule Emoji.Predictions.Prediction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "predictions" do
    field :no_bg_output, :string
    field :emoji_output, :string
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

    timestamps()
  end

  @doc false
  def changeset(prediction, attrs) do
    prediction
    |> cast(attrs, [
      :uuid,
      :prompt,
      :no_bg_output,
      :emoji_output,
      :score,
      :count_votes,
      :is_featured,
      :local_user_id,
      :moderation_score,
      :moderator,
      :embedding,
      :image_embedding,
      :embedding_model
    ])
    |> validate_required([:prompt])
  end
end
