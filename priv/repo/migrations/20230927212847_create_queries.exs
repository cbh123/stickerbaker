defmodule Sticker.Repo.Migrations.CreateQueries do
  use Ecto.Migration

  def change do
    create table(:queries) do
      add :content, :text
      add :embedding, :binary

      timestamps()
    end
  end
end
