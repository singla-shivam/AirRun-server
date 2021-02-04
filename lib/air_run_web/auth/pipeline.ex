defmodule AirRunWeb.Auth.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :air_run,
    module: AirRunWeb.Auth.Guardian,
    error_handler: AirRunWeb.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
