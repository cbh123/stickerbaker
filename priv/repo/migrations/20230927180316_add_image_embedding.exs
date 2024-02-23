defmodule Sticker.Repo.Migrations.AddImageEmbedding do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :image_embedding, :binary
    end
  end
end
