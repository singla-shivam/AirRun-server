defmodule AirRun.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string
      add :user_id, references("users")

      timestamps()
    end

    create unique_index(:projects, [:name])
  end
end
