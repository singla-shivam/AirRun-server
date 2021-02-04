defmodule AirRunWeb.Router do
  use AirRunWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug AirRunWeb.Auth.Pipeline
  end

  forward "/_health", HealthCheckup, resp_body: "Ok"

  scope "/api", AirRunWeb do
    pipe_through :api

    post "/users/signup", UserController, :create
    post "/users/signin", UserController, :signin
  end

  scope "/api", AirRunWeb do
    pipe_through [:api, :auth]

    get "/projects/list", ProjectController, :list
    post "/projects/create", ProjectController, :create
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: AirRunWeb.Telemetry
    end
  end
end
