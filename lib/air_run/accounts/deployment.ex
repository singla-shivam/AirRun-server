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

  def changeset(deployment, params) do
    deployment
    |> cast(params, [:user_id, :project_id])
    |> validate_required(:user_id, message: "user_id_missing")
    |> validate_required(:project_id, message: "project_id_missing")
  end
end
