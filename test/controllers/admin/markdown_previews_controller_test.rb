require "test_helper"

class Admin::MarkdownPreviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
  end

  test "allows authenticated admin to preview markdown" do
    login_as_admin

    post admin_markdown_preview_path, params: { markdown: "# 見出し" }

    assert_response :success
    assert_equal "application/json", response.media_type
    assert_includes response.parsed_body.fetch("html"), "<h1>見出し</h1>"
  end

  test "redirects unauthenticated users to login" do
    post admin_markdown_preview_path, params: { markdown: "# 見出し" }

    assert_redirected_to admin_login_path
  end

  test "converts article body parameter markdown to html" do
    login_as_admin

    post admin_markdown_preview_path, params: { article: { body: "| A | B |\n| - | - |\n| 1 | 2 |" } }

    html = response.parsed_body.fetch("html")
    assert_response :success
    assert_includes html, "<table>"
    assert_includes html, "<td>1</td>"
  end

  test "removes dangerous html" do
    login_as_admin

    post admin_markdown_preview_path, params: { markdown: "<script>alert('x')</script>\n\n# 安全" }

    html = response.parsed_body.fetch("html")
    assert_response :success
    assert_not_includes html, "<script"
    assert_not_includes html, "alert('x')"
    assert_includes html, "<h1>安全</h1>"
  end

  test "handles blank body safely" do
    login_as_admin

    post admin_markdown_preview_path, params: { markdown: "" }

    assert_response :success
    assert_equal "", response.parsed_body.fetch("html")
  end

  test "does not create or update articles" do
    article = Article.create!(title: "既存記事", summary: "概要", body: long_body, status: "draft")
    login_as_admin

    assert_no_difference -> { Article.count } do
      post admin_markdown_preview_path, params: { article: { body: "# Preview only" } }
    end

    assert_equal long_body, article.reload.body
  end

  private
    def login_as_admin
      post admin_login_path, params: { email: @admin.email, password: "password123" }
    end

    def long_body
      "本文" * 200
    end
end
