defmodule AirRun.Repo do
  use Ecto.Repo,
    otp_app: :air_run,
    adapter: Ecto.Adapters.Postgres
end
