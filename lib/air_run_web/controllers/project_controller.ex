defmodule AirRunWeb.ProjectController do
  use AirRunWeb, :controller

  alias AirRun.Accounts
  alias AirRun.Accounts.Project

  action_fallback AirRunWeb.Fallbacks.User

  def list(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    projects = Accounts.list_projects(user.id)

    conn
    |> json(projects)
  end

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
