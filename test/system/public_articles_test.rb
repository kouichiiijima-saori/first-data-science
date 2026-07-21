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
  end

  test "visiting the index" do
    visit articles_url
    assert_selector "h1", text: "記事一覧"
    assert_text @published_article.title
    assert_no_text @draft_article.title
  end

  test "showing a published article" do
    visit article_url(@published_article)
    assert_selector "h1", text: @published_article.title
    assert_text @published_article.summary
  end
end
