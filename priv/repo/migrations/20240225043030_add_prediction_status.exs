defmodule Sticker.Repo.Migrations.AddPredictionStatus do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :status, :string, default: nil
    end
  end
end
