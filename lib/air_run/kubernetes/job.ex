defmodule AirRun.Kubernetes.Job do
  alias AirRun.Kubernetes.{Deployment, KanikoBuildJob}

  import AirRun.Kubernetes.Utilities

  def get_config(project_name, deployment_id, user_id) do
    cwd = File.cwd!()
    path = Path.join(cwd, "priv/kubernetes/deployment-poll-job.yaml")
    {:ok, config} = YamlElixir.read_from_file(path)

    deployment_name = Deployment.get_deployment_name(project_name, deployment_id)
    job_name = deployment_name <> "-poll-job"

    labels = %{
      "job_name" => job_name,
      "deployment_name" => deployment_name,
      "deployment_id" => deployment_id,
      "user_id" => user_id,
      "project_name" => project_name
    }

    config
    |> change_name(job_name, :job)
    |> put_meta_labels(labels, :job)
    |> put_pod_template_labels(labels, :job)
    |> put_env_value("deployment-poll", "DEPLOYMENT_NAME", deployment_name, :job)
  end
end
