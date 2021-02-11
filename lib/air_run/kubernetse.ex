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

end
