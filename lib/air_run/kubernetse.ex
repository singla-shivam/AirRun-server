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
              %{"image" => "k8s-registry:31320/test-kaniko4", "name" => "test-c1"}
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
end
