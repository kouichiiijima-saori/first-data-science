require "test_helper"

class ArticlesRoutesTest < ActionDispatch::IntegrationTest
  test "routes public article read endpoints" do
    assert_recognizes({ controller: "articles", action: "index" }, { method: "get", path: "/" })
    assert_recognizes({ controller: "articles", action: "index" }, { method: "get", path: "/articles" })
    assert_recognizes({ controller: "articles", action: "show", id: "1" }, { method: "get", path: "/articles/1" })
    assert_equal "/articles", articles_path
    assert_equal "/articles/1", article_path(1)
  end

  test "does not expose public article write routes" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/articles", method: :post)
    end

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/articles/1", method: :patch)
    end

    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/articles/1", method: :delete)
    end
  end
end
