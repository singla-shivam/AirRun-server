defmodule AirRun.Accounts.Deployment do
  @derive {Jason.Encoder, only: [:id]}
  use Ecto.Schema
  import Ecto.Changeset
  alias AirRun.Accounts.User

  schema "deployments" do
    field :user_id, :integer
    field :project_id, :integer
    field :status, Ecto.Enum, values: [:created, :built, :deployed]
    field :built_at, :naive_datetime
    field :deployed_at, :naive_datetime

    # belongs_to(:user, User)

    timestamps()
  end

  def changeset(deployment, :built), do: update_status(deployment, :built)
  def changeset(deployment, :deployed), do: update_status(deployment, :deployed)

  def changeset(deployment, params) do
    deployment
    |> cast(params, [:user_id, :project_id])
    |> validate_required(:user_id, message: "user_id_missing")
    |> validate_required(:project_id, message: "project_id_missing")
  end

  defp update_status(deployment, new_status) do
    deployment
    |> change(status: new_status)
    |> put_timestamp(new_status)
  end

  defp put_timestamp(changeset, new_status) do
    case new_status do
      :built -> change(changeset, built_at: NaiveDateTime.local_now())
      :deployed -> change(changeset, deployed_at: NaiveDateTime.local_now())
      _ -> changeset
    end
  end
end
