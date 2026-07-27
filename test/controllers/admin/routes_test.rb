require "test_helper"

class Admin::RoutesTest < ActionDispatch::IntegrationTest
  test "routes admin session endpoints" do
    assert_routing({ method: "get", path: "/admin/login" }, { controller: "admin/sessions", action: "new" })
    assert_routing({ method: "post", path: "/admin/login" }, { controller: "admin/sessions", action: "create" })
    assert_routing({ method: "delete", path: "/admin/logout" }, { controller: "admin/sessions", action: "destroy" })
    assert_routing({ method: "get", path: "/admin" }, { controller: "admin/dashboard", action: "index" })
  end

  test "routes admin article crud endpoints" do
    assert_routing({ method: "get", path: "/admin/articles" }, { controller: "admin/articles", action: "index" })
    assert_routing({ method: "get", path: "/admin/articles/new" }, { controller: "admin/articles", action: "new" })
    assert_routing({ method: "post", path: "/admin/articles" }, { controller: "admin/articles", action: "create" })
    assert_routing({ method: "get", path: "/admin/articles/1/edit" }, { controller: "admin/articles", action: "edit", id: "1" })
    assert_routing({ method: "patch", path: "/admin/articles/1" }, { controller: "admin/articles", action: "update", id: "1" })
    assert_routing({ method: "delete", path: "/admin/articles/1" }, { controller: "admin/articles", action: "destroy", id: "1" })
  end

  test "routes admin markdown preview endpoint" do
    assert_routing({ method: "post", path: "/admin/markdown_preview" }, { controller: "admin/markdown_previews", action: "create" })
  end

  test "routes admin article image upload endpoint" do
    assert_routing({ method: "post", path: "/admin/article_images" }, { controller: "admin/article_images", action: "create" })
  end

  test "does not expose unnecessary restful session routes" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/admin/sessions", method: :get)
    end

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/admin/sessions/new", method: :get)
    end
  end

  test "does not expose admin article show route" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/admin/articles/1", method: :get)
    end
  end
end
