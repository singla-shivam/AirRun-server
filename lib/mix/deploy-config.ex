defmodule Mix.DeployConfig do
  def read_config!() do
    config_path = get_config_path!

    if !File.exists?(config_path) do
      File.write!(config_path, Poison.encode!(%{}))
    end

    File.read!(config_path)
    |> Poison.decode!()
  end

  def write_config!(config) do
    config_path = get_config_path!
    config = Poison.encode!(config, pretty: true)
    File.write!(config_path, config)
  end

  defp get_config_path!() do
    File.cwd!() <> "/deploy-config.json"
  end
end
