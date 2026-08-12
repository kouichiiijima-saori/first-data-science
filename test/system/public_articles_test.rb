require "application_system_test_case"

class PublicArticlesTest < ApplicationSystemTestCase
  setup do
    @published_article = Article.create!(
      title: "公開記事",
      summary: "公開記事の概要",
      body: "本文" * 200,
      status: "published"
    )
    @draft_article = Article.create!(
      title: "下書き記事",
      summary: "下書き記事の概要",
      body: "本文" * 200,
      status: "draft"
    )
    @thumbnail_article = Article.create!(
      title: "サムネイル付き記事",
      summary: "サムネイル画像が設定されている記事の概要",
      body: "本文" * 200,
      status: "published"
    )
    @thumbnail_article.thumbnail.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )
  end

  test "visiting the index" do
    visit articles_url
    assert_selector "h1", text: "記事一覧"
    assert_text @published_article.title
    assert_no_text @draft_article.title
    assert_text @thumbnail_article.title

    within find(".article-card", text: @published_article.title) do
      assert_no_selector ".article-card-thumbnail"
    end

    within find(".article-card", text: @thumbnail_article.title) do
      assert_selector ".article-card-thumbnail"
      assert_selector ".article-card-thumbnail img[alt='#{@thumbnail_article.title}']"
    end
  end


  test "public pages do not show admin login link" do
    visit articles_url
    assert_no_link "管理者ログイン", href: admin_login_path

    visit article_url(@published_article)
    assert_no_link "管理者ログイン", href: admin_login_path
  end

  test "showing a published article" do
    visit article_url(@published_article)
    assert_selector "h1", text: @published_article.title
    assert_text @published_article.summary
    assert_no_selector ".article-detail-thumbnail"
  end

  test "showing a published article with thumbnail" do
    visit article_url(@thumbnail_article)
    assert_selector "h1", text: @thumbnail_article.title
    assert_text @thumbnail_article.summary
    assert_selector ".article-detail-thumbnail"
    assert_selector ".article-detail-thumbnail img[alt='#{@thumbnail_article.title}']"
  end

  test "showing a draft article returns 404" do
    visit article_url(@draft_article)

    assert_no_text @draft_article.title
    assert_no_text @draft_article.summary
  end
end
