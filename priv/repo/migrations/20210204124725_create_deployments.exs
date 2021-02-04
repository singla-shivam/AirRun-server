defmodule AirRun.Repo.Migrations.CreateDeployments do
  use Ecto.Migration

  def change do
    create table(:deployments) do
      add :user_id, references("users")
      add :project_id, references("projects")

      timestamps()
    end
  end
end
