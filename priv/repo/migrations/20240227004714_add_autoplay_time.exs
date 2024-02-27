defmodule Sticker.Repo.Migrations.AddAutoplayTime do
  use Ecto.Migration

  def change do
    alter table(:predictions) do
      add :autoplay_time, :utc_datetime
    end
  end
end
