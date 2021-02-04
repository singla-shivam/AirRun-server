defmodule AirRunWeb.UserControllerTest do
  use AirRunWeb.ConnCase

  alias AirRun.Accounts
  alias AirRun.Accounts.User

  @new_user %{email: "email@email.com", password: "my_password"}

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create user" do
    test "creates user succesfully when it does not exixts", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), @new_user)
      assert %{"token" => id, "user" => user} = json_response(conn, 201)
      assert %{"email" => "email@email.com", "id" => id} = user
    end

    test "returns user already exists", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), @new_user)
      conn = post(conn, Routes.user_path(conn, :create), @new_user)
      assert %{"code" => "user_already_exists"} = json_response(conn, 409)
    end

    test "returns appropriate error messages when input data is not valid", %{conn: conn} do
      # invalid email
      conn =
        post(conn, Routes.user_path(conn, :create), %{
          email: "ASbd",
          password: "my_password"
        })

      assert %{"code" => "invalid_email"} = json_response(conn, 400)

      # missing email
      conn =
        post(conn, Routes.user_path(conn, :create), %{
          password: "my_password"
        })

      assert %{"code" => "missing_email"} = json_response(conn, 400)

      # missing email
      conn =
        post(conn, Routes.user_path(conn, :create), %{
          password: "my"
        })

      assert %{"code" => "missing_email"} = json_response(conn, 400)

      # missing password
      conn =
        post(conn, Routes.user_path(conn, :create), %{
          email: "email@email.com"
        })

      assert %{"code" => "missing_password"} = json_response(conn, 400)
    end
  end

  describe "sign-in user" do
    test "succesfully sign-in users", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), @new_user)
      conn = post(conn, Routes.user_path(conn, :signin), @new_user)
      assert %{"token" => id, "user" => user} = json_response(conn, 200)
      assert %{"email" => "email@email.com", "id" => id} = user
    end

    test "returns user not found", %{conn: conn} do
      conn =
        post(conn, Routes.user_path(conn, :signin), %{
          email: "new_email@email.com",
          password: "password"
        })

      assert %{"code" => "user_not_found"} = json_response(conn, 404)
    end

    test "returns appropriate error messages when input data is not valid", %{conn: conn} do
      # user_not_found in case of invalid email id
      conn =
        post(conn, Routes.user_path(conn, :signin), %{
          email: "ASbd",
          password: "my_password"
        })

      assert %{"code" => "user_not_found"} = json_response(conn, 404)

      # missing email
      conn =
        post(conn, Routes.user_path(conn, :signin), %{
          password: "my_password"
        })

      assert %{"code" => "missing_email_or_pass"} = json_response(conn, 400)

      # missing email
      conn =
        post(conn, Routes.user_path(conn, :signin), %{
          password: "my"
        })

      assert %{"code" => "missing_email_or_pass"} = json_response(conn, 400)

      # missing password
      conn =
        post(conn, Routes.user_path(conn, :signin), %{
          email: "email@email.com"
        })

      assert %{"code" => "missing_email_or_pass"} = json_response(conn, 400)
    end
  end
end
