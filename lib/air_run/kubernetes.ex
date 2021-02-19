defmodule AirRun.Kubernetes do
  use HTTPoison.Base

  def process_request_url(url) do
    k8s_api_host = System.get_env("K8S_APISERVER")
    k8s_api_host <> url
  end

  def process_request_headers(headers) do
    token = System.get_env("K8S_TOKEN")
    Keyword.put(headers, :Authorization, "Bearer " <> token)
  end

  def process_request_options(options) do
    cert_file = System.get_env("K8S_CACERT")
    opts = [ssl_options: [cacertfile: cert_file]]
    Keyword.put(options, :hackney, opts)
  end

  def process_response_body(body) do
    Poison.decode!(body)
  end

  def make_deployment() do
    body = %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{"name" => "test"},
      "spec" => %{
        "selector" => %{"matchLabels" => %{"purpose" => "k8s-api-test"}},
        "template" => %{
          "metadata" => %{"labels" => %{"purpose" => "k8s-api-test"}},
          "spec" => %{
            "containers" => [
              %{"image" => "k8s-registry:31320/my-project-image:15", "name" => "test-c1"}
            ],
            "imagePullSecrets" => [%{"name" => "regcred"}]
          }
        }
      }
    }

    headers = [{"Content-type", "application/json"}]

    case post("/apis/apps/v1/namespaces/default/deployments", Poison.encode!(body), headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        IO.puts("created")
        IO.inspect(body)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)

      x ->
        IO.inspect(x)
    end
  end

  def build_app(project_name, deployment_id, project_path) do
    cwd = File.cwd!()
    path = Path.join(cwd, "priv/kaniko.yml")
    {:ok, kaniko_config} = YamlElixir.read_from_file(path)

    job_name = "#{project_name}-#{deployment_id}-build"
    image_name = "#{project_name}-image:#{deployment_id}"

    # change job name
    kaniko_config = put_in(kaniko_config, ["metadata", "name"], job_name)

    # path in config for container
    kaniko_containers_path = ["spec", "template", "spec", "containers"]
    kaniko_build_args_path = kaniko_containers_path ++ [get_in_index(0), "args"]
    kaniko_poll_args_path = kaniko_containers_path ++ [get_in_index(1), "args"]

    kaniko_containrs = get_in(kaniko_config, kaniko_containers_path)
    kaniko_build_args = get_in(kaniko_config, kaniko_build_args_path)
    kaniko_poll_args = get_in(kaniko_config, kaniko_poll_args_path)

    kaniko_build_args =
      Enum.map(
        kaniko_build_args,
        fn arg ->
          arg
          |> String.replace("Dockerfile", project_path <> "/Dockerfile")
          |> String.replace("image-name", image_name)
          |> String.replace("context-dir", project_path)
        end
      )

    kaniko_poll_args =
      Enum.map(
        kaniko_poll_args,
        fn arg ->
          arg
          |> String.replace("job-name-here", job_name)
        end
      )

    kaniko_build_container = %{Enum.at(kaniko_containrs, 0) | "args" => kaniko_build_args}
    kaniko_poll_container = %{Enum.at(kaniko_containrs, 1) | "args" => kaniko_poll_args}

    kaniko_containrs = [kaniko_build_container, kaniko_poll_container]

    kaniko_config =
      put_in(
        kaniko_config,
        kaniko_containers_path,
        kaniko_containrs
      )

    IO.inspect(kaniko_config)

    headers = [{"Content-type", "application/json"}]

    case post("/apis/batch/v1/namespaces/default/jobs", Poison.encode!(kaniko_config), headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        IO.puts("created")
        IO.inspect(body)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)

      x ->
        IO.inspect(x)
    end
  end

  defp get_in_index(index) do
    fn _, data, next -> data |> Enum.at(index) |> next.() end
  end
end
