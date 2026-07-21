require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "requires title body summary and status" do
    article = Article.new(title: " ", body: " ", summary: " ", status: " ")

    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"
    assert_includes article.errors[:body], "can't be blank"
    assert_includes article.errors[:summary], "can't be blank"
    assert_includes article.errors[:status], "can't be blank"
    assert_not_includes article.errors[:body], plain_text_length_error
  end

  test "allows only draft and published statuses" do
    article = build_article(status: "archived")

    assert_not article.valid?
    assert_includes article.errors[:status], "is not included in the list"
  end

  test "defaults status to draft" do
    article = Article.new(title: "Title", body: long_body, summary: "Summary")

    assert_equal "draft", article.status
  end

  test "uses longtext for body in mysql" do
    assert_equal "longtext", Article.columns_hash.fetch("body").sql_type
  end

  test "has many tags through article tags" do
    article = Article.create!(title: "Title", body: long_body, summary: "Summary", status: "draft")
    tag = Tag.create!(name: "Ruby")

    article.tags << tag

    assert_includes article.tags.reload, tag
    assert_equal article, article.article_tags.first.article
  end

  test "destroys article tags when article is destroyed" do
    article = Article.create!(title: "Title", body: long_body, summary: "Summary", status: "draft")
    tag = Tag.create!(name: "Ruby")
    article_tag = ArticleTag.create!(article: article, tag: tag)

    article.destroy!

    assert_not ArticleTag.exists?(article_tag.id)
  end

  test "can attach thumbnail through active storage" do
    article = Article.create!(title: "Title", body: long_body, summary: "Summary", status: "draft")

    article.thumbnail.attach(io: StringIO.new("image"), filename: "thumbnail.png", content_type: "image/png")

    assert article.thumbnail.attached?
  end

  test "allows body with at least 400 plain text characters" do
    article = build_article(body: "あ" * 400)

    assert article.valid?
  end

  test "rejects body with fewer than 400 plain text characters" do
    article = build_article(body: "あ" * 399)

    assert_not article.valid?
    assert_includes article.errors[:body], plain_text_length_error
  end

  test "does not count repeated markdown symbols toward body length" do
    article = build_article(body: "#" * 500 + "\n短い本文")

    assert_not article.valid?
    assert_includes article.errors[:body], plain_text_length_error
  end

  test "does not count bare urls toward body length" do
    article = build_article(body: "https://example.com/path " * 80)

    assert_not article.valid?
    assert_includes article.errors[:body], plain_text_length_error
  end

  test "counts fenced code block content toward body length" do
    article = build_article(body: "```ruby\n#{'a' * 400}\n```")

    assert article.valid?
  end

  private
    def build_article(attributes = {})
      Article.new({
        title: "Title",
        body: long_body,
        summary: "Summary",
        status: "draft"
      }.merge(attributes))
    end

    def long_body
      "本文" * 200
    end

    def plain_text_length_error
      "must be at least #{Article::MINIMUM_BODY_PLAIN_TEXT_LENGTH} plain text characters"
    end
end
