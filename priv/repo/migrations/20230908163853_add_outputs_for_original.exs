defmodule Emoji.Repo.Migrations.AddOutputsForOriginal do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :emoji_output, :string
    end
  end
end
