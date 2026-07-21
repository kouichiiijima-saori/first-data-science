require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
  end

  test "redirects unauthenticated users to login" do
    get admin_root_path

    assert_redirected_to admin_login_path
  end

  test "allows authenticated admin to access dashboard" do
    login_as_admin

    get admin_root_path

    assert_response :success
    assert_select "h1", "管理画面"
    assert_includes response.body, @admin.email
  end

  test "keeps public health check accessible without admin session" do
    get rails_health_check_path

    assert_response :success
  end

  private
    def login_as_admin
      post admin_login_path, params: { email: @admin.email, password: "password123" }
    end
end
