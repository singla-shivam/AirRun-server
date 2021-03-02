defmodule AirRunWeb.ProjectControllerTest do
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

  describe "create project" do
    test "create project with given name", %{conn: conn} do
      project_name = "abc-def-y7"
      conn = post(conn, Routes.project_path(conn, :create), %{"name" => project_name})
      result = json_response(conn, 201)
      assert ^project_name = result["project"]["name"]
    end

    test "should return conflict if project with given name already exists", %{conn: conn} do
      project_name = "abc-def-y7"
      conn = post(conn, Routes.project_path(conn, :create), %{"name" => project_name})
      conn = post(conn, Routes.project_path(conn, :create), %{"name" => project_name})
      result = json_response(conn, 409)
      assert %{"code" => "project_name_already_exists"} = result
    end

    test "should 400 if project name is missing", %{conn: conn} do
      project_name = "abc-def-y7"
      conn = post(conn, Routes.project_path(conn, :create), %{"name1" => project_name})
      result = json_response(conn, 400)
      assert %{"code" => "missing_project_name"} = result
    end

    test "should 400 if invalid project name is passed", %{conn: conn} do
      invalid_names = [
        "asdf@",
        "-sdfs-sd",
        "sfdsf-sdf-",
        "sdf--sdf",
        "dsf834hs-sdfj37!df",
        "sdf_fsdf",
        "JKidf"
      ]

      for name <- invalid_names do
        conn = post(conn, Routes.project_path(conn, :create), %{"name" => name})
        result = json_response(conn, 400)
        assert %{"code" => "invalid_project_name"} = result
      end
    end
  end

  describe "list projects" do
    test "should return empty list if no project found", %{conn: conn} do
      conn = get(conn, Routes.project_path(conn, :list))
      assert [] = json_response(conn, 200)
    end

    test "should return list of projects", %{conn: conn} do
      project_names = [
        "abc",
        "sdfer-sdf",
        "dsf-e3fa",
        "sdf-3fsa-sdf"
      ]

      for name <- project_names do
        post(conn, Routes.project_path(conn, :create), %{"name" => name})
      end

      conn = get(conn, Routes.project_path(conn, :list))
      response = json_response(conn, 200)
      response_project_names = Enum.map(response, fn r -> r["name"] end)
      assert ^project_names = response_project_names
    end
  end
end
