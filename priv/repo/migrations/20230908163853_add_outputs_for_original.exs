defmodule Sticker.Repo.Migrations.AddOutputsForOriginal do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :sticker_output, :string
    end
  end
end
