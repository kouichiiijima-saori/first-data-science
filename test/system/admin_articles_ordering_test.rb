require "application_system_test_case"

class AdminArticlesOrderingTest < ApplicationSystemTestCase
  setup do
    Article.destroy_all
    @admin = Admin.create!(email: "admin@example.com", password: "password123")

    @article1 = Article.create!(
      title: "記事1", summary: "Summary 1", body: "Body 1" * 100,
      status: "published", editor_type: "markdown", display_order: 1
    )
    @article1.thumbnail.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.jpg")), filename: "sample.jpg")

    @article2 = Article.create!(
      title: "記事2", summary: "Summary 2", body: "Body 2" * 100,
      status: "published", editor_type: "markdown", display_order: 2
    )
    @article2.thumbnail.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.jpg")), filename: "sample.jpg")

    @article3 = Article.create!(
      title: "記事3", summary: "Summary 3", body: "Body 3" * 100,
      status: "published", editor_type: "markdown", display_order: 3
    )
    @article3.thumbnail.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.jpg")), filename: "sample.jpg")
  end

  def login_as_admin
    visit admin_login_path
    fill_in "メールアドレス", with: @admin.email
    fill_in "パスワード", with: "password123"
    click_button "ログイン"
    assert_text "記事管理"
  end

  def assert_admin_titles(expected_titles)
    assert_equal expected_titles, all("tbody tr td:nth-child(2) strong").map(&:text)
  end

  def assert_public_titles(expected_titles)
    assert_equal expected_titles, all(".article-card-body h2").map(&:text)
  end

  test "articles are ordered by display_order in admin index" do
    login_as_admin
    visit admin_articles_path

    titles = all("tbody tr td:nth-child(2) strong").map(&:text)
    assert_equal [ "記事1", "記事2", "記事3" ], titles
  end

  test "articles are ordered by display_order in public index" do
    visit articles_path

    titles = all(".article-card-body h2").map(&:text)
    assert_equal [ "記事1", "記事2", "記事3" ], titles
  end

  test "can move article down and keep order after reload" do
    login_as_admin
    visit admin_articles_path

    within "tbody tr:nth-child(1)" do
      click_on "下へ"
    end

    assert_text "表示順を下に移動しました"
    @article1.reload
    @article2.reload
    assert_equal 2, @article1.display_order
    assert_equal 1, @article2.display_order
    assert_admin_titles [ "記事2", "記事1", "記事3" ]

    visit admin_articles_path
    assert_admin_titles [ "記事2", "記事1", "記事3" ]

    visit articles_path
    assert_public_titles [ "記事2", "記事1", "記事3" ]
  end

  test "can move article up and keep order after reload" do
    login_as_admin
    visit admin_articles_path

    within "tbody tr:nth-child(2)" do
      click_on "上へ"
    end

    assert_text "表示順を上に移動しました"
    @article1.reload
    @article2.reload
    assert_equal 2, @article1.display_order
    assert_equal 1, @article2.display_order
    assert_admin_titles [ "記事2", "記事1", "記事3" ]

    visit admin_articles_path
    assert_admin_titles [ "記事2", "記事1", "記事3" ]

    within "tbody tr:nth-child(1)" do
      click_on "下へ"
    end

    assert_text "表示順を下に移動しました"
    @article1.reload
    @article2.reload
    assert_equal 1, @article1.display_order
    assert_equal 2, @article2.display_order
    assert_admin_titles [ "記事1", "記事2", "記事3" ]
  end

  test "first article cannot be moved up and last cannot be moved down" do
    login_as_admin
    visit admin_articles_path

    within "tbody tr:nth-child(1)" do
      assert_no_button "上へ"
      assert_button "下へ"
    end

    within "tbody tr:nth-child(3)" do
      assert_button "上へ"
      assert_no_button "下へ"
    end
  end

  test "new article gets max display_order + 1" do
    login_as_admin
    visit admin_articles_path
    click_on "新規作成"

    fill_in "タイトル", with: "新規記事4"
    fill_in "概要", with: "Summary 4"
    fill_in "本文 (Markdown)", with: "Body 4 content with enough length to pass validations. " * 10

    click_on "保存する"

    assert_text "記事を作成しました"

    titles = all("tbody tr td:nth-child(2) strong").map(&:text)
    assert_equal [ "記事1", "記事2", "記事3", "新規記事4" ], titles

    new_article = Article.find_by(title: "新規記事4")
    assert_equal 4, new_article.display_order
  end
end
