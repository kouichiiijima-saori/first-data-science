require "test_helper"

class Admin::ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
    @article = Article.create!(
      title: "Existing Article",
      summary: "Existing summary",
      body: "Existing body",
      status: "draft"
    )
  end

  test "redirects unauthenticated users from article admin pages" do
    get admin_articles_path
    assert_redirected_to admin_login_path

    get new_admin_article_path
    assert_redirected_to admin_login_path

    get edit_admin_article_path(@article)
    assert_redirected_to admin_login_path
  end

  test "renders article index for authenticated admin" do
    login_as_admin

    get admin_articles_path

    assert_response :success
    assert_select "h1", "記事管理"
    assert_includes response.body, @article.title
  end

  test "renders new form for authenticated admin" do
    login_as_admin

    get new_admin_article_path

    assert_response :success
    assert_select "form[action=?]", admin_articles_path
    assert_select "input[name='article[title]']"
    assert_select "textarea[name='article[summary]']"
    assert_select "textarea[name='article[body]']"
    assert_select "select[name='article[status]']"
    assert_select "input[name='article[tag_names]']"
    assert_select "input[name='article[thumbnail]']"
  end

  test "creates article with permitted attributes and comma separated tags" do
    login_as_admin

    assert_difference -> { Article.count }, 1 do
      post admin_articles_path, params: {
        article: {
          title: "New Article",
          summary: "New summary",
          body: "New body",
          status: "published",
          tag_names: "Python, Statistics, Python",
          created_at: 1.year.ago
        }
      }
    end

    article = Article.order(:created_at).last
    assert_redirected_to admin_articles_path
    assert_equal "New Article", article.title
    assert_equal "New summary", article.summary
    assert_equal "New body", article.body
    assert_equal "published", article.status
    assert_equal %w[Python Statistics], article.tags.order(:name).pluck(:name)
    assert_operator article.created_at, :>, 1.minute.ago
  end

  test "rerenders new with validation errors" do
    login_as_admin

    assert_no_difference -> { Article.count } do
      post admin_articles_path, params: {
        article: {
          title: "",
          summary: "",
          body: "",
          status: "published",
          tag_names: "Python"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "記事新規作成"
    assert_select ".errors"
    assert_includes response.body, "Python"
  end

  test "updates article and replaces tags" do
    login_as_admin
    @article.tags << Tag.create!(name: "Old")

    patch admin_article_path(@article), params: {
      article: {
        title: "Updated Article",
        summary: "Updated summary",
        body: "Updated body",
        status: "published",
        tag_names: "Machine Learning, Data"
      }
    }

    @article.reload
    assert_redirected_to admin_articles_path
    assert_equal "Updated Article", @article.title
    assert_equal "Updated summary", @article.summary
    assert_equal "Updated body", @article.body
    assert_equal "published", @article.status
    assert_equal [ "Data", "Machine Learning" ], @article.tags.order(:name).pluck(:name)
  end

  test "rerenders edit with validation errors" do
    login_as_admin

    patch admin_article_path(@article), params: {
      article: {
        title: "",
        summary: "Summary",
        body: "Body",
        status: "draft",
        tag_names: "Draft"
      }
    }

    assert_response :unprocessable_entity
    assert_select "h1", "記事編集"
    assert_select ".errors"
    assert_includes response.body, "Draft"
  end

  test "destroys article" do
    login_as_admin

    assert_difference -> { Article.count }, -1 do
      delete admin_article_path(@article)
    end

    assert_redirected_to admin_articles_path
  end

  private
    def login_as_admin
      post admin_login_path, params: { email: @admin.email, password: "password123" }
    end
end
