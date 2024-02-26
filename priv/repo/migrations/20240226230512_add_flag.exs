defmodule Sticker.Repo.Migrations.AddFlag do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :flag, :string
    end
  end
end
