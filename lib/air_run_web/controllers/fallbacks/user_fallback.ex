defmodule AirRunWeb.Fallbacks.User do
  use AirRunWeb, :controller

  alias AirRunWeb.{Utilities}

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    error = get_changeset_error(changeset)

    {status, code} = error_to_status(error)

    conn
    |> put_status(status)
    |> json(%{code: code})
  end

  def call(conn, {:error, :user_not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{code: :user_not_found})
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{code: :unauthorized})
  end

  def call(conn, error) do
    IO.inspect(error)
    send_resp(conn, 500, to_string(error))
  end

  defp error_to_status(error) do
    case error do
      :user_already_exists -> {:conflict, "user_already_exists"}
      :invalid_email -> {:bad_request, "invalid_email"}
      :missing_email -> {:bad_request, "missing_email"}
      :missing_password -> {:bad_request, "missing_password"}
      :short_password -> {:bad_request, "short_password"}
      :project_name_already_exists -> {:conflict, "project_name_already_exists"}
      :missing_project_name -> {:bad_request, "missing_project_name"}
      _ -> {:unprocessable_entity, "unprocessable_entity"}
    end
  end

  defp get_changeset_error(changeset) do
    errors_tuple = Utilities.translate_errors(changeset)

    case errors_tuple do
      %{email: ["user_already_exists"]} -> :user_already_exists
      %{email: ["invalid_email"]} -> :invalid_email
      %{email: ["missing_email"]} -> :missing_email
      %{email: ["missing_email"], password: ["missing_password"]} -> :missing_email
      %{password: ["missing_password"]} -> :missing_password
      %{password: ["short_password"]} -> :short_password
      %{name: ["missing_project_name"]} -> :missing_project_name
      %{name: ["project_name_already_exists"]} -> :project_name_already_exists
      _ -> :unprocessable_entity
    end
  end
end
