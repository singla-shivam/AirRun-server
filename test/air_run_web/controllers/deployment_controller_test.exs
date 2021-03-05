defmodule AirRunWeb.DeploymentControllerTest do
  use AirRunWeb.ConnCase

  alias AirRun.Accounts
  alias AirRun.Accounts.User

  @new_user %{email: "email@email.com", password: "my_password"}

  def fixture(:signup) do
    conn = post(build_conn(), "/api/users/signup", @new_user)
    conn
    |> response(201)
    |> Poison.decode!()
  end

  setup %{conn: conn} do
    conn = put_req_header(conn, "accept", "application/json")
    res = fixture(:signup)
    token = res["token"]
    conn = put_req_header(conn, "authorization", "Bearer #{token}")
    {:ok, conn: conn}
  end

#  describe "list deployments" do
#    test "should return empty list if no project found", %{conn: conn} do
#      conn = get(conn, Routes.project_path(conn, :list))
#      assert [] = json_response(conn, 200)
#    end
#
#    test "should return list of projects", %{conn: conn} do
#      project_names = [
#        "abc",
#        "sdfer-sdf",
#        "dsf-e3fa",
#        "sdf-3fsa-sdf"
#      ]
#
#      for name <- project_names do
#        post(conn, Routes.project_path(conn, :create), %{"name" => name})
#      end
#
#      conn = get(conn, Routes.project_path(conn, :list))
#      response = json_response(conn, 200)
#      response_project_names = Enum.map(response, fn r -> r["name"] end)
#      assert ^project_names = response_project_names
#    end
#  end
end
