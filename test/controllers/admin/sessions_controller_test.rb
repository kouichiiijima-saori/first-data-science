require "test_helper"

class Admin::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
  end

  test "renders login form" do
    get admin_login_path

    assert_response :success
    assert_select "input[name=email]"
    assert_select "input[name=password]"
    assert_select "input[type=submit][value=?]", "ログイン"
  end

  test "logs in with correct email and password" do
    post admin_login_path, params: { email: @admin.email, password: "password123" }

    assert_equal @admin.id, session[:admin_id]
    assert_nil session[:password]
    assert_nil session[:password_digest]
    assert_redirected_to admin_root_path
  end

  test "normalizes email before authentication" do
    post admin_login_path, params: { email: "  ADMIN@EXAMPLE.COM  ", password: "password123" }

    assert_equal @admin.id, session[:admin_id]
    assert_redirected_to admin_root_path
  end

  test "redirects already logged in admin away from login form" do
    login_as_admin

    get admin_login_path

    assert_redirected_to admin_root_path
  end

  test "fails with unknown email using generic message" do
    post admin_login_path, params: { email: "missing@example.com", password: "password123" }

    assert_response :unprocessable_entity
    assert_nil session[:admin_id]
    assert_select ".alert", Admin::SessionsController::AUTHENTICATION_ERROR_MESSAGE
  end

  test "fails with wrong password using same generic message" do
    post admin_login_path, params: { email: @admin.email, password: "wrong-password" }

    assert_response :unprocessable_entity
    assert_nil session[:admin_id]
    assert_select ".alert", Admin::SessionsController::AUTHENTICATION_ERROR_MESSAGE
  end

  test "does not redisplay password after failed login" do
    post admin_login_path, params: { email: @admin.email, password: "wrong-password" }

    assert_no_match "wrong-password", response.body
    assert_select "input[name=password][value]", false
  end

  test "logs out logged in admin" do
    login_as_admin

    delete admin_logout_path

    assert_nil session[:admin_id]
    assert_redirected_to admin_login_path
  end

  test "does not allow protected page after logout" do
    login_as_admin
    delete admin_logout_path

    get admin_root_path

    assert_redirected_to admin_login_path
  end

  test "redirects unauthenticated logout request to login" do
    delete admin_logout_path

    assert_redirected_to admin_login_path
  end

  private
    def login_as_admin
      post admin_login_path, params: { email: @admin.email, password: "password123" }
    end
end
