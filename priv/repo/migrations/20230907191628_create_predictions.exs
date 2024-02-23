defmodule Sticker.Repo.Migrations.CreatePredictions do
  use Ecto.Migration

  def change do
    create table(:predictions) do
      add :uuid, :string
      add :prompt, :string
      add :output, :string

      timestamps()
    end
  end
end
