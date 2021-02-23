defmodule AirRun.Kubernetes.KanikoBuildJob do
  alias AirRun.Utilities

  import AirRun.Kubernetes.Utilities

  @containers_path ["spec", "template", "spec", "containers"]
  @k8s_registry "k8s-registry:31320"
  @build_container_name "kaniko-build"

  def get_kaniko_config(project_name, deployment_id, project_path) do
    project_path = Path.relative(project_path)

    cwd = File.cwd!()
    path = Path.join(cwd, "priv/kaniko.yaml")
    {:ok, kaniko_config} = YamlElixir.read_from_file(path)

    job_name = get_job_name(project_name, deployment_id)
    image_name = get_image_name(project_name, deployment_id)

    labels = %{
      "deployment_id" =>  deployment_id,
      "project_name" => project_name,
      "job_name" => job_name,
      "image_name" => image_name,
    }

    kaniko_config
    |> change_name(job_name, :job)
    |> put_meta_labels(labels, :job)
    |> put_pod_template_labels(labels, :job)
    |> put_build_args(project_path, image_name, job_name)
    |> put_env_value("kaniko-poll", "JOB_NAME", job_name, :job)
  end

  def get_image_name(project_name, deployment_id) do
    "#{project_name}-image:#{deployment_id}"
  end

  def get_registry_address(), do: @k8s_registry

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

  defp put_build_args(config, project_path, image_name, job_name) do
    build_args_path = @containers_path ++ [get_in_index(0), "args"]

    containers = get_containers(config, :job)
    build_args = get_in(config, build_args_path)

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

    build_container = get_container(config, @build_container_name, :job)
    build_container = %{build_container | "args" => build_args}

    replace_container(
      config,
      @build_container_name,
      build_container,
      :job
    )
  end

  defp put_poll_environment(config, job_name) do
    poll_env_path = @containers_path ++ [get_in_index(1), "env"]

    containers = get_in(config, @containers_path)
    poll_env = get_in(config, poll_env_path)

    job_name_env = %{
      "name" => "JOB_NAME",
      "value" => job_name,
    }

    poll_env = Enum.map(
      poll_env,
      fn arg ->
        if arg["name"] == "JOB_NAME" do
          job_name_env
        else
          arg
        end
      end
    )

    poll_container = %{Enum.at(containers, 1) | "env" => poll_env}
    containers = List.replace_at(containers, 1, poll_container)

    put_in(
      config,
      @containers_path,
      containers
    )
  end

  defp get_in_index(index) do
    fn _, data, next ->
      data
      |> Enum.at(index)
      |> next.() end
  end
end
