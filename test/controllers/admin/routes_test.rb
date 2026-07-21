require "test_helper"

class Admin::RoutesTest < ActionDispatch::IntegrationTest
  test "routes admin session endpoints" do
    assert_routing({ method: "get", path: "/admin/login" }, { controller: "admin/sessions", action: "new" })
    assert_routing({ method: "post", path: "/admin/login" }, { controller: "admin/sessions", action: "create" })
    assert_routing({ method: "delete", path: "/admin/logout" }, { controller: "admin/sessions", action: "destroy" })
    assert_routing({ method: "get", path: "/admin" }, { controller: "admin/dashboard", action: "index" })
  end

  test "does not expose unnecessary restful session routes" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/admin/sessions", method: :get)
    end

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/admin/sessions/new", method: :get)
    end
  end
end
