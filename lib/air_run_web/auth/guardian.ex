defmodule AirRunWeb.Auth.Guardian do
  use Guardian, otp_app: :air_run

  alias AirRun.Accounts

  @doc false
  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  @doc false
  def resource_from_claims(claims) do
    id = claims["sub"]
    resource = Accounts.get_user!(id)
    IO.inspect(resource)
    {:ok, resource}
  end

  @doc """
  Validates a user by email and password.

  Returns: {:ok, user, token}, {:error, :unauthorized}, {:error, :user_not_found}
  """
  def authenticate(email, password) do
    with {:ok, user} <- Accounts.get_by_email(email) do
      case validate_password(password, user.encrypted_password) do
        true -> create_token(user)
        false -> {:error, :unauthorized}
      end
    end
  end

  # Compares passed password with the encrypted password
  defp validate_password(password, encrypted_password) do
    Comeonin.Bcrypt.checkpw(password, encrypted_password)
  end

  # Creates token from the user struct passed
  defp create_token(user) do
    {:ok, token, _claims} = encode_and_sign(user)
    {:ok, user, token}
  end
end
