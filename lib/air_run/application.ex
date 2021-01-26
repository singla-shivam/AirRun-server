defmodule AirRun.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      AirRun.Repo,
      # Start the Telemetry supervisor
      AirRunWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: AirRun.PubSub},
      # Start the Endpoint (http/https)
      AirRunWeb.Endpoint
      # Start a worker by calling: AirRun.Worker.start_link(arg)
      # {AirRun.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AirRun.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AirRunWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
