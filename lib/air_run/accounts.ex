defmodule AirRun.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias AirRun.Repo

  alias AirRun.Accounts.User
  alias AirRun.Accounts.Project
  alias AirRun.Accounts.Deployment

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Retreives a user by their email id
  """
  def get_by_email(email) do
    case Repo.get_by(User, email: email) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  def get_project_by_id(project_id) do
    Repo.get(Project, project_id)
  end

  def list_projects(user_id) do
    Repo.all(Project, user_id: user_id)
  end

  def create_project(attrs \\ %{}) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  def list_deployments(user_id) do
    Repo.all(Deployment, user_id: user_id)
  end

  def create_deployment(user_id, project_id) do
    %Deployment{}
    |> Deployment.changeset(%{"user_id" => user_id, "project_id" => project_id})
    |> Repo.insert()
  end
end
