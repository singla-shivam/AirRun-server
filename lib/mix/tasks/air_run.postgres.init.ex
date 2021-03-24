defmodule Mix.Tasks.AirRun.Postgres.Init do
  def run(_args) do
    password = ask_password()
    database = ask_database_name()
    release_name = ask_release_name()
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

  defp ask_database_name() do
    default = "air-run-prod"
    database = Mix.shell().prompt("Name of database? [#{default}]") |> String.trim()
    if database == "", do: default, else: database
  end

  defp ask_release_name() do
    default = "air-run-postgres"
    release_name = Mix.shell().prompt("Helm release name? [#{default}]") |> String.trim()
    if release_name == "", do: default, else: release_name
  end
end
