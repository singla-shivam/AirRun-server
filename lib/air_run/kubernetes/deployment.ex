defmodule AirRun.Kubernetes.Deployment do
  alias AirRun.Kubernetes.KanikoBuildJob

  import AirRun.Kubernetes.Utilities

  @deployment_container_name "deployment-main"

  def get_deployment_config(project_name, deployment_id, user_id) do
    cwd = File.cwd!()
    path = Path.join(cwd, "priv/deployment.yaml")
    {:ok, config} = YamlElixir.read_from_file(path)

    deployment_name = get_deployment_name(project_name, deployment_id)
    image_name = KanikoBuildJob.get_image_name(project_name, deployment_id)
    registry_address = KanikoBuildJob.get_registry_address()

    labels = %{
      "deployment_name" => deployment_name,
      "deployment_id" => deployment_id,
      "user_id" => user_id,
      "project_name" => project_name
    }

    config
    |> change_name(deployment_name, :deployment)
    |> put_meta_labels(labels, :deployment)
    |> put_selector_labels(labels, :deployment)
    |> put_pod_template_labels(labels, :deployment)
    |> put_image_name(registry_address <> "/" <> image_name)
  end

  def get_deployment_name(project_name, deployment_id) do
    "#{project_name}-#{deployment_id}-deployment"
  end

  def from_deployment_name(deployment_name) do
    %{
      "deployment_id" => deployment_id,
      "project_name" => project_name
    } = Regex.named_captures(Utilities.deployment_name_regex(), deployment_name)

    deployment_id = String.to_integer(deployment_id)

    %{
      "deployment_id" => deployment_id,
      "project_name" => project_name
    }
  end

  defp put_image_name(config, image_name) do
    main_container = get_container(config, @deployment_container_name, :deployment)
    main_container = %{main_container | "image" => image_name}
    replace_container(config, @deployment_container_name, main_container, :deployment)
  end
end
