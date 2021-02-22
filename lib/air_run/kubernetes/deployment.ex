defmodule AirRun.Kubernetes.Deployment do
  alias AirRun.Kubernetes.KanikoBuildJob

  import AirRun.Kubernetes.Utilities

  def get_deployment_config(project_name, deployment_id, user_id) do
    cwd = File.cwd!()
    path = Path.join(cwd, "priv/deployment.yaml")
    {:ok, config} = YamlElixir.read_from_file(path)

    deployment_name = get_deployment_name(project_name, deployment_id)
    image_name = KanikoBuildJob.get_image_name(project_name, deployment_id)
    registry_address = KanikoBuildJob.get_registry_address

    labels = %{
      "deployment_id" =>  deployment_id,
      "user_id" => user_id,
      "project_name" => project_name,
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

  defp change_name(config, deployment_name) do
    put_in(config, ["metadata", "name"], deployment_name)
  end

  defp put_meta_labels(config, labels) do
    put_in(config, ["metadata", "labels"], labels)
  end

  defp put_selector_labels(config, labels) do
    put_in(config, ["spec", "selector", "matchLabels"], labels)
  end

  defp put_pod_template_labels(config, labels) do
    put_in(config, ["spec", "template", "metadata", "labels"], labels)
  end

  defp put_image_name(config, image_name) do
    containers_path = ["spec", "template", "spec", "containers"]

    containers = get_in(config, containers_path)
    main_container = Enum.at(containers, 0)
    main_container = %{main_container | "image" => image_name}
    containers = List.replace_at(containers, 0, main_container)

    put_in(config, containers_path, containers)
  end
end