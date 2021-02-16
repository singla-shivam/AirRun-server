defmodule AirRun.Accounts.Project do
  @derive {Jason.Encoder, only: [:name, :user_id, :id, :prog_lang]}
  use Ecto.Schema
  import Ecto.Changeset
  alias AirRun.Accounts.User

  schema "projects" do
    field :name, :string
    field :user_id, :integer
    field :prog_lang, :string

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :user_id])
    |> foreign_key_constraint(:user_id)
    |> validate_required(:name, message: "missing_project_name")
    |> unique_constraint(:name, message: "project_name_already_exists")
  end
end
