defmodule AirRunWeb.DeploymentController do
  use AirRunWeb, :controller

  alias AirRun.{Accounts, Kubernetes}
  alias AirRun.Accounts.Deployment
  alias AirRun.Kubernetes.KanikoBuildJob
  alias AirRunWeb.Utilities

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
    {:ok, deployment} = Accounts.create_deployment(user.id, project_id)
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

  def built_callback(conn, params) do
    params = Utilities.parse_callback_body(params)
    job_name = params["job_name"]
    %{
      "deployment_id" => deployment_id,
      "project_name" => project_name
    } = KanikoBuildJob.from_job_name(job_name)

    deployment = Accounts.mark_deployment_built(deployment_id)
    Kubernetes.make_deployment(project_name, deployment_id, deployment.user_id)

    send_resp(conn, 202, "")
  end

  def deployed_callback(conn, params) do
    params = Utilities.parse_callback_body(params)
    IO.inspect(params)
    deployment_name = params["deployment_name"]
    send_resp(conn, 202, "")
  end
end
