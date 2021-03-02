defmodule AirRunWeb.ProjectController do
  @moduledoc """
    Controller which user-projects related functionalities.
  """

  use AirRunWeb, :controller

  alias AirRun.Accounts
  alias AirRun.Accounts.Project

  action_fallback AirRunWeb.Fallbacks.User

  @doc """
  List the projects of the user. The user need to be authenticated.

  The project name **MUST** contain English lower-case letters, digits
  and the hyphen (-). The name **MUST NOT** start or end with hyphen and
  **MUST NOT** contain two or more consecutive hyphens.

  Sends 400 with one possible errors -
    * "missing_project_name"
    * "invalid_project_name"

  Sends 409 with one possible errors -
    * "project_name_already_exists"
  """
  @spec list(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    projects = Accounts.list_projects(user.id)

    conn
    |> json(projects)
  end

  @doc """
  Create a new project. The user need to be authenticated.
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, project_params) do
    user = Guardian.Plug.current_resource(conn)
    project_params = Map.put(project_params, "user_id", user.id)

    result =
      with {:ok, %Project{} = project} <- Accounts.create_project(project_params) do
        conn
        |> put_status(:created)
        |> json(%{project: project})
      end
  end
end
