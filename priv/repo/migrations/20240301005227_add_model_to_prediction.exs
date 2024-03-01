defmodule Sticker.Repo.Migrations.AddModelToPrediction do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :model, :string
    end
  end
end
