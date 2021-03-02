defmodule AirRunWeb.UserController do
  @moduledoc """
  Controller which is responsible for authenticating user.

  It uses JWT token strategy for authentication using
  [Guardian](https://hexdocs.pm/guardian/Guardian.html). The `user_id`
  is used the subject for token.

  Currently, sign-in with email and password is supported.
  """

  use AirRunWeb, :controller

  alias AirRun.Accounts
  alias AirRun.Accounts.User
  alias AirRunWeb.Auth.Guardian
  alias AirRun.Kubernetes

  action_fallback AirRunWeb.Fallbacks.User

  @doc """
  Creates a new user from the given user parameters(email, password)

  Sends 201 if created successfully.

  Sends 400 with one possible errors -
    * "invalid_email"
    * "missing_email"
    * "missing_password"
    * "unprocessable_entity"

  Sends 409 with one possible errors -
    * "user_already_exists"
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, user_params) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      conn
      |> put_status(:created)
      |> json(%{user: user, token: token})
    end
  end

  @doc """
  Sign-in's the user

  Sends 200, if successfully signed in.

  Sends 400 bad request when either email or password, or both are missing

  Sends 404 when the user with given email id does not exist
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def signin(conn, params)

  def signin(conn, %{"email" => email, "password" => password}) do
    with {:ok, user, token} <- Guardian.authenticate(email, password) do
      conn
      |> put_status(:ok)
      |> json(%{user: user, token: token})
    end
  end

  def signin(conn, _) do
    conn
    |> put_status(:bad_request)
    |> json(%{code: "missing_email_or_pass"})
  end
end
