require "test_helper"

class ArticleTagTest < ActiveSupport::TestCase
  test "belongs to article and tag" do
    article = Article.create!(title: "Title", body: "Body", summary: "Summary", status: "draft")
    tag = Tag.create!(name: "Ruby")
    article_tag = ArticleTag.create!(article: article, tag: tag)

    assert_equal article, article_tag.article
    assert_equal tag, article_tag.tag
  end

  test "rejects duplicate article and tag pair" do
    article = Article.create!(title: "Title", body: "Body", summary: "Summary", status: "draft")
    tag = Tag.create!(name: "Ruby")
    ArticleTag.create!(article: article, tag: tag)

    duplicate = ArticleTag.new(article: article, tag: tag)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:tag_id], "has already been taken"
  end

  test "enforces duplicate article and tag pair at the database layer" do
    article = Article.create!(title: "Title", body: "Body", summary: "Summary", status: "draft")
    tag = Tag.create!(name: "Ruby")
    ArticleTag.create!(article: article, tag: tag)

    assert_raises(ActiveRecord::RecordNotUnique) do
      ArticleTag.insert_all!([
        { article_id: article.id, tag_id: tag.id, created_at: Time.current, updated_at: Time.current }
      ])
    end
  end

  test "enforces foreign key constraints" do
    tag = Tag.create!(name: "Ruby")

    assert_raises(ActiveRecord::InvalidForeignKey) do
      ArticleTag.insert_all!([
        { article_id: -1, tag_id: tag.id, created_at: Time.current, updated_at: Time.current }
      ])
    end
  end
end
