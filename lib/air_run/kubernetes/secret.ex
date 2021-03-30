defmodule AirRun.Kubernetes.Secret do
  import AirRun.Kubernetes.Utilities

  def get_secret_config(secret_name, options \\ []) do
    cwd = File.cwd!()
    path = Path.join(cwd, "priv/kubernetes/secret.yaml")

    {:ok, config} = YamlElixir.read_from_file(path)

    config
    |> change_name(secret_name, :secret)
  end

  def put_string_data(config, data) do
    Map.put(config, "stringData", data)
  end
end
