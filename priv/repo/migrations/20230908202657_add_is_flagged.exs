defmodule Sticker.Repo.Migrations.AddIsFlagged do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :is_flagged, :string
    end
  end
end
