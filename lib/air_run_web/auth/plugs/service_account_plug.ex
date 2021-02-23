defmodule AirRunWeb.Auth.ServiceAccountPlug do
  use Plug.Builder

  plug :basic_auth

  defp basic_auth(conn, opts) do
    username = System.fetch_env!("SERVICE_ACCOUNT_USERNAME")
    password = System.fetch_env!("SERVICE_ACCOUNT_PASSWORD")
    Plug.BasicAuth.basic_auth(conn, username: username, password: password)
  end
end
