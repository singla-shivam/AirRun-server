defmodule AirRun.Utilities do
  def project_name_regex() do
    ~r/^(?!-)[a-zA-Z\d\-]+(?<!-)$/
  end

  def build_job_name_regex() do
    ~r/^(?!-)(?<project_name>[a-zA-Z\-]+)-(?<deployment_id>[\d]+)-build$/
  end
end
