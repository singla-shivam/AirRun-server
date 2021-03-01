defmodule AirRun.Kubernetes do
  use HTTPoison.Base

  alias AirRun.Kubernetes.{KanikoBuildJob, Deployment, Service}

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

  def make_deployment(project_name, deployment_id, user_id) do
    deployment_config = Deployment.get_deployment_config(project_name, deployment_id, user_id)

    headers = [{"Content-type", "application/json"}]

    case post(
           "/apis/apps/v1/namespaces/default/deployments",
           Poison.encode!(deployment_config),
           headers
         ) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        IO.puts("created")

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)

      x ->
        IO.inspect(x)
    end
  end

  def build_app(project_name, deployment_id, project_path) do
    kaniko_config = KanikoBuildJob.get_kaniko_config(project_name, deployment_id, project_path)

    headers = [{"Content-type", "application/json"}]

    case post("/apis/batch/v1/namespaces/default/jobs", Poison.encode!(kaniko_config), headers) do
      {:ok, %HTTPoison.Response{status_code: 201, body: body}} ->
        IO.puts("created")

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)

      x ->
        IO.inspect(x)
    end
  end

  def create_service(project_name, deployment_id, user_id) do
    service_config = Service.get_service_config(project_name, deployment_id, user_id)
    headers = [{"Content-type", "application/json"}]

    case post("/api/v1/namespaces/default/services", Poison.encode!(service_config), headers) do
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
end
