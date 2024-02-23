defmodule Sticker.Repo.Migrations.AddModerationStuff do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :moderation_score, :integer, default: nil
      add :moderator, :text
    end
  end
end
