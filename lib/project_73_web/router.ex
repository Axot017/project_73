defmodule Project73Web.Router do
  use Project73Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Project73Web.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers

    plug Project73Web.Plug.SetLanguage
    plug Project73Web.Plug.FetchProfile
    plug Project73Web.Plug.CheckProfile
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Project73Web do
    pipe_through :api

    scope "/v1" do
    end
  end

  scope "/", Project73Web do
    pipe_through :browser

    live "/", HomeLive
    get "/login", PageController, :login
    live "/auction/new", NewAuctionLive

    scope "/auth" do
      delete "/logout", AuthController, :delete

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end

    scope "/profile" do
      live "/update", ProfileUpdateLive
      live "/wallet", WalletLive
    end
  end

  if Application.compile_env(:project_73, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: Project73Web.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
