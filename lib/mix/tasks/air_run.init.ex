defmodule Mix.Tasks.AirRun.Init do
  use GenServer

  alias Mix.DeployConfig
  alias Mix.Utilities
  alias AirRun.Kubernetes.Secret

  @impl true
  def init(:ok) do
    config = DeployConfig.read_config!()
    {:ok, config}
  end

  @impl true
  def handle_call({:update, keys, value}, _from, config) do
    keys = Enum.map(keys, fn key -> Access.key(key, %{}) end)
    config = put_in(config, keys, value)
    DeployConfig.write_config!(config)
    {:reply, nil, config}
  end

  @impl true
  def handle_call({:get, path}, _from, config) do
    value = get_in(config, path)
    {:reply, value, config}
  end

  defp tick(server, current_step \\ nil) do
    case current_step do
      nil ->
        generate_guardian_secret(server)

      :guardian ->
        generate_secret_key_base(server)

      :secret_key ->
        generate_database_url(server)

      :database_url ->
        ask_air_run_server_username(server)

      :server_username ->
        ask_air_run_server_password(server)

      :server_password ->
        apply_secret(server, ["air-run-secret"], "air-run", :apply_general_secret)

      :apply_general_secret ->
        apply_secret(
          server,
          ["air-run-service-secret"],
          "air-run-service-account-basic-auth",
          :apply_service_secret
        )

      :apply_service_secret ->
        deploy_server(server)

      _ ->
        raise("Unknown step: " <> to_string(current_step))
    end
  end

  def run(_args) do
    {:ok, task} = GenServer.start_link(Mix.Tasks.AirRun.Init, :ok)
    tick(task)
  end

  def create_app_secrets() do
    secret_config = Secret.get_secret_config("air-run-server")
  end

  defp generate_database_url(server) do
    Mix.shell().info("Generating database url")
    postgres_config = GenServer.call(server, {:get, ["postgres"]})

    username = "postgres"
    password = postgres_config["password"]
    service_name = postgres_config["release_name"]
    database_name = postgres_config["database_name"]

    url = "ecto://#{username}:#{password}@#{service_name}-postgresql/#{database_name}"

    GenServer.call(server, {:update, ["air-run-secret", "database-url"], url})
    tick(server, :database_url)
  end

  defp ask_air_run_server_username(server) do
    path = ["air-run-service-secret", "username"]
    ask_required_secret(server, path, :server_username)
  end

  defp ask_air_run_server_password(server) do
    path = ["air-run-service-secret", "password"]
    ask_required_secret(server, path, :server_password)
  end

  defp generate_secret_key_base(server) do
    path = ["air-run-secret", "secret-key-base"]
    generate_secret(server, path, :secret_key)
  end

  defp generate_guardian_secret(server) do
    path = ["air-run-secret", "guardian-secret-key"]
    generate_secret(server, path, :guardian)
  end

  defp deploy_server(server) do
  end

  defp generate_secret(server, path, step, override? \\ false) do
    secret = GenServer.call(server, {:get, path})

    names = [guardian: "guardian secret", secret_key: "secret key base"]
    name = names[step]

    if secret != nil and !override? do
      is_yes = prompt("A #{name} already exists. Generate new?", false)

      if is_yes,
        do: generate_secret(server, path, step, true),
        else: tick(server, step)
    else
      Mix.shell().info("Generating #{name}")

      Mix.Shell.cmd(
        "mix guardian.gen.secret",
        fn x ->
          x = String.trim(x)
          GenServer.call(server, {:update, path, x})
          tick(server, step)
        end
      )
    end
  end

  defp ask_required_secret(server, path, step) do
    default = GenServer.call(server, {:get, path})

    names = [
      server_username: {"air-run service", "Username"},
      server_password: {"air-run service", "Password"},
      k8s_registry_username: {"k8s-registry", "Username"},
      k8s_registry_password: {"k8s-registry", "Password"}
    ]

    {purpose, name} = names[step]

    data =
      Mix.shell().prompt("#{name} for #{purpose}? [#{default}]")
      |> String.trim()

    cond do
      data == "" and default == nil ->
        ask_required_secret(server, path, step)

      data == "" ->
        tick(server, step)

      true ->
        GenServer.call(server, {:update, path, data})
        tick(server, step)
    end
  end

  defp prompt(message, default \\ true) do
    if default do
      Mix.shell().yes?(message)
    else
      res =
        Mix.shell().prompt(message <> " [y/N]")
        |> String.trim()
        |> String.downcase()

      res == "y"
    end
  end

  defp apply_secret(server, path, secret_name, step) do
    data = GenServer.call(server, {:get, path})

    data =
      if String.contains?(secret_name, "auth"),
        do: data,
        else: Utilities.capitalize_keys(data)

    secret =
      Secret.get_secret_config(secret_name)
      |> Secret.put_string_data(data)
      |> Poison.encode!()

    Mix.Shell.cmd(
      "echo '#{secret}' | kubectl apply -f -",
      fn x ->
        IO.puts(x)
        tick(server, step)
      end
    )
  end

  defp get_k8s_creds(server) do
    username = GenServer.call(server, {:get, ["k8s-registry", "username"]})
    password = GenServer.call(server, {:get, ["k8s-registry", "password"]})

    {username, password}
  end
end
