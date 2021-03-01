defmodule AirRun.Kubernetes.Service do
  import AirRun.Kubernetes.Utilities

  def get_service_config(project_name, deployment_id, user_id) do
    cwd = File.cwd!()
    path = Path.join(cwd, "priv/service.yaml")
    {:ok, config} = YamlElixir.read_from_file(path)

    service_name = get_service_name(project_name, deployment_id)

    selector_labels = %{
      "project_name" => project_name,
      "user_id" => user_id
    }

    labels =
      Map.merge(
        selector_labels,
        %{
          "service_name" => service_name,
          "deployment_id" => deployment_id
        }
      )

    config
    |> change_name(service_name, :service)
    |> put_meta_labels(labels, :service)
    |> put_selector_labels(selector_labels, :service)
  end

  def get_service_name(project_name, deployment_id) do
    "#{project_name}-#{deployment_id}-service"
  end
end
