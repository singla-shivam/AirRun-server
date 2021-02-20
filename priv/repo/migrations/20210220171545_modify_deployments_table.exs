defmodule AirRun.Repo.Migrations.ModifyDeploymentsTable do
  use Ecto.Migration

  def change do
    alter table(:deployments) do
      add :status, :string, default: "created"
      add :built_at, :naive_datetime
      add :deployed_at, :naive_datetime
    end
  end
end
