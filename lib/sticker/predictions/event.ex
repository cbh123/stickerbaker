defmodule Sticker.Predictions.Event do
  use Ecto.Schema

  schema "events" do
    field :event_name, :string
    timestamps()
  end
end
