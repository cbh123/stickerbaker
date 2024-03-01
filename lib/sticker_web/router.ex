defmodule StickerWeb.Router do
  use StickerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {StickerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :admins_only do
    plug :admin_basic_auth
  end

  defp admin_basic_auth(conn, _opts) do
    username = System.fetch_env!("ADMIN_USERNAME")
    password = System.fetch_env!("ADMIN_PASSWORD")

    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end

  scope "/admin", StickerWeb do
    pipe_through [:browser, :admins_only]
    import Phoenix.LiveDashboard.Router

    live "/", AdminLive, :index
    live_dashboard "/dashboard", metrics: StickerWeb.Telemetry
  end

  scope "/", StickerWeb do
    pipe_through :browser

    live "/", HomeLive, :index
    live "/sticker/:id", ShowLive, :show
    live "/stickers", HistoryLive, :index
    live "/search", SearchLive, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", StickerWeb do
    pipe_through :api
    post "/session", SessionController, :set
  end

  scope "/webhooks", StickerWeb do
    post "/replicate", ReplicateWebhookController, :handle
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:sticker, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
