defmodule Mix.Tasks.AirRun.Postgres.Init do
  alias Mix.DeployConfig

  def run(_args) do
    config = DeployConfig.read_config!()
    postgres_config = config["postgres"] || %{}

    password = ask_password()
    database = ask_database_name(postgres_config["database_name"])
    release_name = ask_release_name(postgres_config["release_name"])

    postgres_config = %{
      "password" => password,
      "database_name" => database,
      "release_name" => release_name
    }

    config = Map.put(config, "postgres", postgres_config)

    DeployConfig.write_config!(config)

    _run(password, database, release_name)
  end

  defp _run(password, database, release_name) do
    shell = Mix.shell()
    helm_repo = "helm repo add bitnami https://charts.bitnami.com/bitnami"

    values =
      %{
        "postgresqlPassword" => password,
        "postgresqlDatabase" => database,
        "primary.nodeSelector.air-run-postgres" => "Schedule"
      }
      |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
      |> Enum.join(",")

    helm_install = "helm install #{release_name} --set #{values} bitnami/postgresql"

    shell.cmd(helm_repo)
    shell.cmd(helm_install)
  end

  defp ask_password() do
    password = Mix.shell().prompt("Password for Postgres?") |> String.trim()
    if password == "", do: ask_password(), else: password
  end

  defp ask_database_name(default) do
    default = default || "air-run-prod"
    database = Mix.shell().prompt("Name of database? [#{default}]") |> String.trim()
    if database == "", do: default, else: database
  end

  defp ask_release_name(default) do
    default = default || "air-run-postgres"
    release_name = Mix.shell().prompt("Helm release name? [#{default}]") |> String.trim()
    if release_name == "", do: default, else: release_name
  end
end
