defmodule Sticker.Repo.Migrations.AddFeatured do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :is_featured, :string
    end
  end
end
