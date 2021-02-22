defmodule AirRun.Kubernetes.Utilities do
  def put_meta_labels(config, labels, _resource_type) do
    labels = sanitize_labels(labels)
    put_in(config, ["metadata", "labels"], labels)
  end

  def put_selector_labels(config, labels, _resource_type) do
    labels = sanitize_labels(labels)
    put_in(config, ["spec", "selector", "matchLabels"], labels)
  end

  def put_pod_template_labels(config, labels, _resource_type) do
    labels = sanitize_labels(labels)
    put_in(config, ["spec", "template", "metadata", "labels"], labels)
  end

  def change_name(config, deployment_name, _resource_type) do
    put_in(config, ["metadata", "name"], deployment_name)
  end

  defp sanitize_labels(labels) do
    for {key, value} <- labels, into: %{} do
      value = value
              |> to_string
              |> String.replace(":", "--")
      {key, to_string(value)}
    end
  end
end