defmodule Sticker.Repo.Migrations.AddEmbeddingsModel do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :embedding_model, :text
    end
  end
end
