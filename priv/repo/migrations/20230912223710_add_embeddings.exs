defmodule Sticker.Repo.Migrations.AddEmbeddings do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :embedding, :binary
    end
  end
end
