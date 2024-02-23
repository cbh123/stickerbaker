defmodule Sticker.Repo do
  use Ecto.Repo,
    otp_app: :sticker,
    adapter: Ecto.Adapters.Postgres
end
