# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :air_run,
  ecto_repos: [AirRun.Repo]

# Configures the endpoint
config :air_run, AirRunWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MkV/Q15lGzmIx3l17OhZ7A3EipP0H7AdJpccdH9k9cRHSPAQVlZVhIrc0e39X6Qc",
  render_errors: [view: AirRunWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: AirRun.PubSub,
  live_view: [signing_salt: "Z0Ki1RKk"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :air_run, AirRunWeb.Guardian,
  issuer: "air_run",
  secret_key: "NQK1IY/k3rmq9Msv5tuAoWeut1SOUyCb6NXt7mZbaSmW8y+fIFZUMR9lDaxiLGem"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
