defmodule AirRun.Kubernetes.KanikoBuildJob do
  alias AirRun.Utilities

  def get_kaniko_config(project_name, deployment_id, project_path) do
    cwd = File.cwd!()
    path = Path.join(cwd, "priv/kaniko.yaml")
    {:ok, kaniko_config} = YamlElixir.read_from_file(path)

    job_name = get_job_name(project_name, deployment_id)
    image_name = get_image_name(project_name, deployment_id)

    kaniko_config
    |> change_job_name(job_name)
    |> replace_container_params(project_path, image_name, job_name)
  end

  def get_image_name(project_name, deployment_id) do
    "#{project_name}-image:#{deployment_id}"
  end

  def get_registry_address(), do: "k8s-registry:31320"

  def get_job_name(project_name, deployment_id) do
    "#{project_name}-#{deployment_id}-build"
  end

  def from_job_name(job_name) do
    %{
      "deployment_id" => deployment_id,
      "project_name" => project_name
    } = Regex.named_captures(Utilities.build_job_name_regex(), job_name)
    deployment_id = String.to_integer(deployment_id)
    %{
      "deployment_id" => deployment_id,
      "project_name" => project_name
    }

  end

  defp change_job_name(kaniko_config, job_name) do
    put_in(kaniko_config, ["metadata", "name"], job_name)
  end

  defp replace_container_params(config, project_path, image_name, job_name) do
    containers_path = ["spec", "template", "spec", "containers"]
    build_args_path = containers_path ++ [get_in_index(0), "args"]
    poll_args_path = containers_path ++ [get_in_index(1), "args"]

    containers = get_in(config, containers_path)
    build_args = get_in(config, build_args_path)
    poll_args = get_in(config, poll_args_path)

    build_args =
      Enum.map(
        build_args,
        fn arg ->
          arg
          |> String.replace("Dockerfile", project_path <> "/Dockerfile")
          |> String.replace("image-name", image_name)
          |> String.replace("context-dir", project_path)
        end
      )

    poll_args =
      Enum.map(
        poll_args,
        fn arg ->
          arg
          |> String.replace("job-name-here", job_name)
        end
      )

    build_container = %{Enum.at(containers, 0) | "args" => build_args}
    poll_container = %{Enum.at(containers, 1) | "args" => poll_args}

    containers = [build_container, poll_container]

    put_in(
      config,
      containers_path,
      containers
    )
  end

  defp get_in_index(index) do
    fn _, data, next -> data |> Enum.at(index) |> next.() end
  end
end
