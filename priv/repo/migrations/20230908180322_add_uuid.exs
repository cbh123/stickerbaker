defmodule Sticker.Repo.Migrations.AddUuid do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :local_user_id, :string
    end
  end
end
