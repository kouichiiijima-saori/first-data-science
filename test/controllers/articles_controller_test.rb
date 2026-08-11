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


  test "public pages do not show admin login link" do
    get articles_path

    assert_response :success
    assert_select "a[href='#{admin_login_path}']", false
    assert_not_includes response.body, "管理者ログイン"

    get article_path(@newer_article)

    assert_response :success
    assert_select "a[href='#{admin_login_path}']", false
    assert_not_includes response.body, "管理者ログイン"
  end

  test "show preserves rich text code blocks and safe internal sample data link" do
    article = create_article(
      editor_type: "rich_text",
      body: %(<p>#{long_body}</p><p><a href="/sample-data/sales_data.csv">演習用CSV</a></p><pre onclick="alert(1)"><code style="color: red">print(&quot;hello&quot;)</code></pre><script>alert(2)</script>)
    )

    get article_path(article)

    assert_response :success
    assert_select ".rich-text-body a[href='/sample-data/sales_data.csv']", "演習用CSV"
    assert_select ".rich-text-body pre code", /print\("hello"\)/
    assert_select ".rich-text-body pre[onclick]", false
    assert_select ".rich-text-body code[style]", false
    assert_select ".rich-text-body script", false
    assert_not_includes response.body, "alert(1)"
    assert_not_includes response.body, "alert(2)"
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

  test "show renders rich text article with allowed formatting" do
    article = create_article(
      editor_type: "rich_text",
      body: %(<h2>リッチ見出し</h2><p><span style="font-size: 1.25rem; color: #2563EB;">装飾本文</span><u>下線</u><a href="https://example.com" target="_blank">リンク</a></p>#{long_body})
    )

    get article_path(article)

    assert_response :success
    assert_select ".rich-text-body h2", "リッチ見出し"
    assert_select ".rich-text-body span[style*='font-size: 1.25rem']", "装飾本文"
    assert_select ".rich-text-body span[style*='color: #2563EB']", "装飾本文"
    assert_select ".rich-text-body u", "下線"
    assert_select ".rich-text-body a[href='https://example.com'][target='_blank'][rel='noopener noreferrer']", "リンク"
  end

  test "show renders rich text active storage image with dimensions" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "body.png",
      content_type: "image/png"
    )
    image_url = rails_blob_path(blob, only_path: true)
    article = create_article(
      editor_type: "rich_text",
      body: %(<p>#{long_body}</p><img src="#{image_url}" alt="本文画像" width="320" height="240">)
    )
    article.body_images.attach(blob)

    get article_path(article)

    assert_response :success
    assert_select ".rich-text-body img[src='#{image_url}'][alt='本文画像'][width='320'][height='240']"
  end

  test "show removes unsafe rich text html and external images" do
    article = create_article(
      editor_type: "rich_text",
      body: %(<h1>大見出し</h1><p onclick="alert(1)">#{long_body}</p><script>alert(1)</script><iframe src="https://example.com"></iframe><a href="javascript:alert(1)">危険リンク</a><img src="https://example.com/image.png"><span style="font-size: 99px; color: red; background-image: url(javascript:alert(1))">危険style</span>)
    )

    get article_path(article)

    assert_response :success
    assert_select ".rich-text-body h2", "大見出し"
    assert_select ".rich-text-body script", false
    assert_select ".rich-text-body iframe", false
    assert_select ".rich-text-body [onclick]", false
    assert_select ".rich-text-body a[href^='javascript']", false
    assert_select ".rich-text-body img", false
    assert_not_includes response.body, "background-image"
    assert_not_includes response.body, "99px"
    assert_not_includes response.body, "color: red"
    assert_not_includes response.body, "alert(1)"
  end

  test "draft rich text article is not public" do
    article = create_article(editor_type: "rich_text", status: "draft", body: "<p>#{long_body}</p>")

    get article_path(article)

    assert_response :not_found
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
