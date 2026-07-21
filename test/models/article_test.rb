require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "requires title body summary and status" do
    article = Article.new(title: " ", body: " ", summary: " ", status: " ")

    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"
    assert_includes article.errors[:body], "can't be blank"
    assert_includes article.errors[:summary], "can't be blank"
    assert_includes article.errors[:status], "can't be blank"
  end

  test "allows only draft and published statuses" do
    article = build_article(status: "archived")

    assert_not article.valid?
    assert_includes article.errors[:status], "is not included in the list"
  end

  test "defaults status to draft" do
    article = Article.new(title: "Title", body: "Body", summary: "Summary")

    assert_equal "draft", article.status
  end

  test "uses longtext for body in mysql" do
    assert_equal "longtext", Article.columns_hash.fetch("body").sql_type
  end

  test "has many tags through article tags" do
    article = Article.create!(title: "Title", body: "Body", summary: "Summary", status: "draft")
    tag = Tag.create!(name: "Ruby")

    article.tags << tag

    assert_includes article.tags.reload, tag
    assert_equal article, article.article_tags.first.article
  end

  test "destroys article tags when article is destroyed" do
    article = Article.create!(title: "Title", body: "Body", summary: "Summary", status: "draft")
    tag = Tag.create!(name: "Ruby")
    article_tag = ArticleTag.create!(article: article, tag: tag)

    article.destroy!

    assert_not ArticleTag.exists?(article_tag.id)
  end

  test "can attach thumbnail through active storage" do
    article = Article.create!(title: "Title", body: "Body", summary: "Summary", status: "draft")

    article.thumbnail.attach(io: StringIO.new("image"), filename: "thumbnail.png", content_type: "image/png")

    assert article.thumbnail.attached?
  end

  private
    def build_article(attributes = {})
      Article.new({
        title: "Title",
        body: "Body",
        summary: "Summary",
        status: "draft"
      }.merge(attributes))
    end
end
