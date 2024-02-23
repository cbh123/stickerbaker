defmodule Emoji.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      EmojiWeb.Telemetry,
      # Start the Ecto repository
      Emoji.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Emoji.PubSub},
      # Start Finch
      {Finch, name: Emoji.Finch},
      # Start the Endpoint (http/https)
      EmojiWeb.Endpoint
      # {Emoji.Embeddings.Index, []},
      # Emoji.Embeddings.Worker
      # Start a worker by calling: Emoji.Worker.start_link(arg)
      # {Emoji.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Emoji.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EmojiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
