defmodule Emoji.Repo.Migrations.AddVotesToPredictions do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :score, :integer, default: 0
      add :count_votes, :integer, default: 0
    end
  end
end
