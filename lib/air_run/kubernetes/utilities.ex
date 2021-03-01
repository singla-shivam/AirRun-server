defmodule AirRun.Kubernetes.Utilities do
  @type t :: map()
  @type resource_type :: :deployment | :job
  @type labels :: map()
  @type container :: map()

  @containers_path ["spec", "template", "spec", "containers"]

  @doc """
  Puts the labels in the metadata of the config
  """
  @spec put_meta_labels(t(), labels(), resource_type()) :: t()
  def put_meta_labels(config, labels, _resource_type) do
    labels = sanitize_labels(labels)
    put_in(config, ["metadata", "labels"], labels)
  end

  def put_selector_labels(config, labels, :service) do
    labels = sanitize_labels(labels)
    put_in(config, ["spec", "selector"], labels)
  end

  @doc """
  Puts the labels as selector match labels in the config
  """
  @spec put_selector_labels(t(), labels(), resource_type()) :: t()
  def put_selector_labels(config, labels, _resource_type) do
    labels = sanitize_labels(labels)
    put_in(config, ["spec", "selector", "matchLabels"], labels)
  end

  @doc """
  Puts the labels in the metadata of the the pod template in the config
  """
  @spec put_pod_template_labels(t(), labels(), resource_type()) :: t()
  def put_pod_template_labels(config, labels, _resource_type) do
    labels = sanitize_labels(labels)
    put_in(config, ["spec", "template", "metadata", "labels"], labels)
  end

  @doc """
  Changes the meta-name of the config passed
  """
  @spec change_name(t(), String.t(), resource_type()) :: t()
  def change_name(config, name, _resource_type) do
    put_in(config, ["metadata", "name"], name)
  end

  @doc """
  Put environment variable with name `env_name` in the container specified.
  Inserts new environment variable if it does exists already.

  ## Parameters
  * config - The config of any workload
  * container_name - The name of the container whose environment variable to insert/change
  * env_name - The name of the environment variable
  * env_value - The value of the environment variable
  * _resource_type
  """
  @spec put_env_value(t(), String.t(), String.t(), String.t(), resource_type()) :: t()
  def put_env_value(config, container_name, env_name, env_value, _resource_type) do
    container = get_container(config, container_name, _resource_type)
    env_variables = container["env"]

    env_variables =
      replace_when(
        env_variables,
        fn el -> el["name"] == env_name end,
        fn el -> %{el | "value" => env_value} end
      )

    container = %{container | "env" => env_variables}

    replace_container(config, container_name, container, _resource_type)
  end

  @doc """
  Retrieves list of containers from config with given resource type
  """
  @spec get_containers(t(), resource_type()) :: [container()]
  def get_containers(config, _resource_type) do
    get_in(config, @containers_path)
  end

  @doc """
  Replaces the list of containers in given `config` with given list `containers`
  """
  @spec replace_containers(t(), String.t(), resource_type()) :: t()
  def replace_containers(config, containers, _resource_type) do
    put_in(config, @containers_path, containers)
  end

  @doc """
  Retrieves the container with given `container_name` from `config`
  """
  @spec get_container(t(), String.t(), resource_type()) :: container()
  def get_container(config, container_name, _resource_type) do
    containers = get_containers(config, _resource_type)
    Enum.find(containers, fn c -> c["name"] == container_name end)
  end

  @doc """
  Replace the container with given `container_name` in `config`
  with given `container`
  """
  @spec replace_container(t(), String.t(), container(), resource_type()) :: container()
  def replace_container(config, container_name, container, _resource_type) do
    containers = get_containers(config, _resource_type)

    containers =
      replace_when(
        containers,
        fn c -> c["name"] == container_name end,
        fn _ -> container end
      )

    replace_containers(config, containers, _resource_type)
  end

  defp sanitize_labels(labels) do
    for {key, value} <- labels, into: %{} do
      value =
        value
        |> to_string
        |> String.replace(":", "--")

      {key, to_string(value)}
    end
  end

  defp replace_when(list, condition, value) do
    list =
      Enum.map(
        list,
        fn element ->
          if condition.(element), do: value.(element), else: element
        end
      )

    element = Enum.find(list, fn el -> condition.(el) end)
    if element == nil, do: list ++ [value.()], else: list
  end
end
