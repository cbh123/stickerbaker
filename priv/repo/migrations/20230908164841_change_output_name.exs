defmodule Sticker.Repo.Migrations.ChangeOutputName do
  use Ecto.Migration

  def change do
    rename table("predictions"), :output, to: :no_bg_output
  end
end
