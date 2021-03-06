defmodule AirRun.Utilities do
  def project_name_regex() do
    ~r/^[a-z\d]+(\-[a-z\d]+)*$/
  end

  def build_job_name_regex() do
    ~r/^(?!-)(?<project_name>[a-zA-Z\-]+)-(?<deployment_id>[\d]+)-build$/
  end

  def deployment_name_regex() do
    ~r/^(?!-)(?<project_name>[a-zA-Z\-]+)-(?<deployment_id>[\d]+)-deployment$/
  end
end
