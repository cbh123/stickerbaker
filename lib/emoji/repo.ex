defmodule Emoji.Repo do
  use Ecto.Repo,
    otp_app: :emoji,
    adapter: Ecto.Adapters.Postgres
end
