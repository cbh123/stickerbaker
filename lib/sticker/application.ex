defmodule Sticker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Logger.add_backend(Sentry.LoggerBackend)

    children = [
      # Start the Telemetry supervisor
      StickerWeb.Telemetry,
      # Start the Ecto repository
      Sticker.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Sticker.PubSub},
      # Start Finch
      {Finch, name: Sticker.Finch},
      # Start the Endpoint (http/https)
      StickerWeb.Endpoint,
      Sticker.Autoplay,
      {Sticker.Embeddings.Index, []},
      Sticker.Embeddings.Worker
      # Start a worker by calling: Sticker.Worker.start_link(arg)
      # {Sticker.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sticker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StickerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
