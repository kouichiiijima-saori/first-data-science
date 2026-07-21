require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @older_article = create_article(
      title: "古い公開記事",
      summary: "古い記事の概要",
      status: "published",
      created_at: 2.days.ago
    )
    @newer_article = create_article(
      title: "新しい公開記事",
      summary: "新しい記事の概要",
      status: "published",
      created_at: 1.day.ago
    )
    @draft_article = create_article(
      title: "下書き記事",
      summary: "下書き記事の概要",
      status: "draft",
      created_at: Time.current
    )
    @newer_article.tags << Tag.create!(name: "Python")
  end

  test "index is accessible without authentication" do
    get articles_path

    assert_response :success
  end

  test "index shows published articles" do
    get articles_path

    assert_response :success
    assert_includes response.body, @newer_article.title
    assert_includes response.body, @older_article.title
  end

  test "index does not show draft articles" do
    get articles_path

    assert_response :success
    assert_not_includes response.body, @draft_article.title
    assert_not_includes response.body, @draft_article.summary
  end

  test "index succeeds when there are no published articles" do
    Article.published.destroy_all

    get articles_path

    assert_response :success
    assert_select ".empty-articles", "公開中の記事はありません。"
  end

  test "index orders articles by created_at descending" do
    get articles_path

    assert_response :success
    assert response.body.index(@newer_article.title) < response.body.index(@older_article.title)
  end

  test "index shows tags" do
    get articles_path

    assert_response :success
    assert_includes response.body, "Python"
  end

  test "index succeeds without thumbnail" do
    get articles_path

    assert_response :success
    assert_select "img", 0
  end

  test "show displays a published article without authentication" do
    get article_path(@newer_article)

    assert_response :success
    assert_select "h1", @newer_article.title
    assert_includes response.body, @newer_article.summary
  end

  test "show returns not found for draft article" do
    get article_path(@draft_article)

    assert_response :not_found
  end

  test "show returns not found for draft article even when admin is logged in" do
    admin = Admin.create!(email: "admin@example.com", password: "password123")
    post admin_login_path, params: { email: admin.email, password: "password123" }

    get article_path(@draft_article)

    assert_response :not_found
  end

  test "show returns not found for missing article" do
    get article_path(id: Article.maximum(:id).to_i + 1)

    assert_response :not_found
  end

  test "show renders markdown heading as html" do
    article = create_article(body: "# 見出し\n\n#{long_body}")

    get article_path(article)

    assert_response :success
    assert_select ".markdown-body h1", "見出し"
  end

  test "show renders markdown table as html" do
    article = create_article(body: "| A | B |\n| - | - |\n| 1 | 2 |\n\n#{long_body}")

    get article_path(article)

    assert_response :success
    assert_select ".markdown-body table"
    assert_select ".markdown-body td", "1"
  end

  test "show renders markdown code block as html" do
    article = create_article(body: "```ruby\nputs 1\n```\n\n#{long_body}")

    get article_path(article)

    assert_response :success
    assert_select ".markdown-body pre code.language-ruby", /puts 1/
  end

  test "show removes dangerous html from markdown body" do
    article = create_article(body: "<script>alert('x')</script>\n\n# 安全な見出し\n\n#{long_body}")

    get article_path(article)

    assert_response :success
    assert_select ".markdown-body script", false
    assert_select ".markdown-body", { text: /alert('x')/, count: 0 }
    assert_select ".markdown-body h1", "安全な見出し"
  end

  test "show displays title summary and tags" do
    get article_path(@newer_article)

    assert_response :success
    assert_select "h1", @newer_article.title
    assert_includes response.body, @newer_article.summary
    assert_includes response.body, "Python"
  end

  test "show succeeds without thumbnail" do
    get article_path(@newer_article)

    assert_response :success
    assert_select "img", 0
  end

  private
    def create_article(attributes = {})
      Article.create!({
        title: "公開記事",
        summary: "公開記事の概要",
        body: long_body,
        status: "published"
      }.merge(attributes))
    end

    def long_body
      "本文" * 200
    end
end
