defmodule AirRunWeb.DeploymentController do
  use AirRunWeb, :controller

  alias AirRun.{Accounts, Kubernetes}
  alias AirRun.Accounts.Deployment

  action_fallback AirRunWeb.Fallbacks.User

  def list(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    deployments = Accounts.list_deployments(user.id)

    conn
    |> json(deployments)
  end

  def create(conn, params) do
    project_id = params["project_id"]
    user = Guardian.Plug.current_resource(conn)
    {:ok, deployment} = Accounts.create_dummy_deployment()
    project = Accounts.get_project_by_id(project_id)

    if file = params["file"] do
      extension = Path.extname(file.filename)
      cwd = File.cwd!()

      source_docker_file_path = "#{cwd}/priv/python/Dockerfile"
      project_path = "user_#{user.id}/#{project.name}_#{project.id}"
      root_path = "#{cwd}/uploads/#{project_path}"
      artifact_name = "deploy_#{deployment.id}"
      zip_name = artifact_name <> extension
      zip_path = "#{root_path}/#{zip_name}"
      artifact_path = "#{root_path}/#{artifact_name}"
      artifact_relative_path = "#{project_path}/#{artifact_name}"
      dest_docker_file_path = "#{root_path}/#{artifact_name}/Dockerfile"

      File.mkdir_p(root_path)
      File.cp(file.path, zip_path)
      {:ok, _} = :zip.unzip(to_char_list(zip_path), cwd: to_char_list(artifact_path))

      File.cp(source_docker_file_path, dest_docker_file_path)
      Kubernetes.build_app(project.name, deployment.id, artifact_relative_path)

      send_resp(conn, 202, "")
    else
      send_resp(conn, 400, "No file provided")
    end
  end

  def callback(conn, params) do
    body = params

    if body["_json"] != nil do
      body = Poison.decode!(body["_json"])
    end

    IO.inspect(body)

    send_resp(conn, 202, "")
  end
end
