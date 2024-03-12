defmodule Sticker.Repo.Migrations.AddEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :event_name, :string

      timestamps()
    end
  end
end
