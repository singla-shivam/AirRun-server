defmodule AirRun.Accounts.User do
  @derive {Jason.Encoder, only: [:email, :id]}
  use Ecto.Schema
  import Ecto.Changeset
  alias Comeonin

  schema "users" do
    field :email, :string
    field :encrypted_password, :string
    field :password, :string, virtual: true

    timestamps()
  end

  @doc """
  Validates the user attributes anc calculates encrypted password
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required(:email, message: "missing_email")
    |> validate_required(:password, message: "missing_password")
    |> validate_format(:email, ~r/^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/,
      message: "invalid_email"
    )
    |> validate_length(:password, min: 6)
    |> unique_constraint(:email, message: "user_already_exists")
    |> put_hashed_password
  end

  @doc """
  Puts encrypted password into the changeset
  """
  defp put_hashed_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
        put_change(changeset, :encrypted_password, Bcrypt.hash_pwd_salt(password))

      _ ->
        changeset
    end
  end
end
