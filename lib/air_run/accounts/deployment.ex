defmodule AirRun.Accounts.Deployment do
  use Ecto.Schema
  alias AirRun.Accounts.User

  schema "deployments" do
    field :user_id, :integer
    field :project_id, :integer

    # belongs_to(:user, User)

    timestamps()
  end
end
