defmodule AirRunWeb.UserController do
  use AirRunWeb, :controller

  alias AirRun.Accounts
  alias AirRun.Accounts.User
  alias AirRunWeb.Guardian

  action_fallback AirRunWeb.Fallbacks.User

  @doc """
  Creates a new user from the given user parameters(email, password)

  Sends 201 if created succesfully.
  Possible errors are -
    * "user_already_exists"
    * "invalid_email"
    * "missing_email"
    * "missing_password"
    * "unprocessable_entity"
  """
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

  Sends 200, if succefully signed in
  Possible errors are -
    * "user_not_found"
  """
  def signin(conn, %{"email" => email, "password" => password}) do
    with {:ok, user, token} <- Guardian.authenticate(email, password) do
      conn
      |> put_status(:ok)
      |> json(%{user: user, token: token})
    end
  end

  @doc """
  Sends 400 bad request when either email or password, or both are missing
  """
  def signin(conn, _) do
    conn
    |> put_status(:bad_request)
    |> json(%{code: "missing_email_or_pass"})
  end
end
