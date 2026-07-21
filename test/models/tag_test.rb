require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "normalizes name before saving" do
    tag = Tag.create!(name: "  Ruby  ")

    assert_equal "Ruby", tag.name
  end

  test "requires name" do
    tag = Tag.new(name: " ")

    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "rejects duplicate name ignoring case" do
    Tag.create!(name: "Ruby")
    duplicate = Tag.new(name: " ruby ")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "enforces unique name at the database layer" do
    Tag.create!(name: "Ruby")

    assert_raises(ActiveRecord::RecordNotUnique) do
      Tag.insert_all!([
        { name: "ruby", created_at: Time.current, updated_at: Time.current }
      ])
    end
  end

  test "has many articles through article tags" do
    tag = Tag.create!(name: "Ruby")
    article = Article.create!(title: "Title", body: "Body", summary: "Summary", status: "draft")

    tag.articles << article

    assert_includes tag.articles.reload, article
    assert_equal tag, tag.article_tags.first.tag
  end

  test "destroys article tags when tag is destroyed" do
    tag = Tag.create!(name: "Ruby")
    article = Article.create!(title: "Title", body: "Body", summary: "Summary", status: "draft")
    article_tag = ArticleTag.create!(article: article, tag: tag)

    tag.destroy!

    assert_not ArticleTag.exists?(article_tag.id)
  end
end
