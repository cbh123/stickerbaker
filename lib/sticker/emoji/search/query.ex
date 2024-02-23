defmodule Sticker.Search.Query do
  use Ecto.Schema
  import Ecto.Changeset

  schema "queries" do
    field :content, :string
    field :embedding, :binary

    timestamps()
  end

  @doc false
  def changeset(query, attrs) do
    query
    |> cast(attrs, [:content, :embedding])
    |> validate_required([:content])
  end
end
