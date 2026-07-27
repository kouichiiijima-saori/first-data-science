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

  test "allows markdown editor type" do
    article = build_article(editor_type: "markdown")

    assert article.valid?
  end

  test "allows rich text editor type" do
    article = build_article(editor_type: "rich_text")

    assert article.valid?
  end

  test "rejects invalid editor type" do
    article = build_article(editor_type: "plain_text")

    assert_not article.valid?
    assert_includes article.errors.full_messages, "編集方式を正しく選択してください"
  end

  test "rejects nil editor type" do
    article = build_article(editor_type: nil)

    assert_not article.valid?
    assert_includes article.errors.full_messages, "編集方式を選択してください"
  end

  test "defaults editor type to markdown" do
    article = Article.new(title: "Title", body: long_body, summary: "Summary")

    assert_equal Article::DEFAULT_EDITOR_TYPE, article.editor_type
  end

  test "uses non nullable markdown default editor type column" do
    column = Article.columns_hash.fetch("editor_type")

    assert_not column.null
    assert_equal Article::DEFAULT_EDITOR_TYPE, column.default
  end

  test "keeps existing body unchanged when editor type default is applied" do
    article = Article.create!(title: "Title", body: long_body, summary: "Summary", status: "draft")

    article.reload

    assert_equal long_body, article.body
    assert_equal "markdown", article.editor_type
  end

  test "does not allow changing editor type after create" do
    article = Article.create!(title: "Title", body: long_body, summary: "Summary", status: "draft")
    original_body = article.body

    assert_not article.update(editor_type: "rich_text")
    assert_includes article.errors.full_messages, "編集方式は保存済み記事では変更できません"

    article.reload
    assert_equal "markdown", article.editor_type
    assert_equal original_body, article.body
  end

  test "allows title with 120 characters" do
    article = build_article(title: "あ" * Article::TITLE_MAX_LENGTH)

    assert article.valid?
  end

  test "rejects title with 121 characters" do
    article = build_article(title: "あ" * (Article::TITLE_MAX_LENGTH + 1))

    assert_not article.valid?
    assert_includes article.errors.full_messages, "タイトルは120文字以内で入力してください"
  end

  test "allows summary with 500 characters" do
    article = build_article(summary: "あ" * Article::SUMMARY_MAX_LENGTH)

    assert article.valid?
  end

  test "rejects summary with 501 characters" do
    article = build_article(summary: "あ" * (Article::SUMMARY_MAX_LENGTH + 1))

    assert_not article.valid?
    assert_includes article.errors.full_messages, "概要は500文字以内で入力してください"
  end

  test "allows body with maximum markdown source length" do
    article = build_article(body: "あ" * Article::BODY_MAX_LENGTH)

    assert article.valid?
  end

  test "rejects body exceeding maximum markdown source length" do
    article = build_article(body: "あ" * (Article::BODY_MAX_LENGTH + 1))

    assert_not article.valid?
    assert_includes article.errors.full_messages, "本文は15,000文字以内で入力してください"
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

  test "has many body images separate from thumbnail" do
    article = build_article(editor_type: "rich_text")
    article.body_images.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "body.png",
      content_type: "image/png"
    )

    assert article.body_images.attached?
    assert_not article.thumbnail.attached?
  end

  test "allows article without thumbnail" do
    article = build_article

    assert article.valid?
  end

  test "allows jpeg thumbnail" do
    article = build_article
    attach_fixture_thumbnail(article, filename: "sample.jpg", content_type: "image/jpeg")

    assert article.valid?
  end

  test "allows png thumbnail" do
    article = build_article
    attach_fixture_thumbnail(article, filename: "sample.png", content_type: "image/png")

    assert article.valid?
  end

  test "allows webp thumbnail" do
    article = build_article
    attach_fixture_thumbnail(article, filename: "sample.webp", content_type: "image/webp")

    assert article.valid?
  end

  test "allows uppercase thumbnail extension" do
    article = build_article
    attach_fixture_thumbnail(article, filename: "PHOTO.JPG", content_type: "image/jpeg")

    assert article.valid?
  end

  test "rejects svg thumbnail" do
    article = build_article
    attach_string_thumbnail(article, filename: "bad.svg", content_type: "image/svg+xml")

    assert_not article.valid?
    assert_includes article.errors[:thumbnail], thumbnail_content_type_error
    assert_includes article.errors[:thumbnail], thumbnail_extension_error
  end

  test "rejects html thumbnail" do
    article = build_article
    attach_string_thumbnail(article, filename: "bad.html", content_type: "text/html")

    assert_not article.valid?
    assert_includes article.errors[:thumbnail], thumbnail_content_type_error
    assert_includes article.errors[:thumbnail], thumbnail_extension_error
  end

  test "rejects pdf thumbnail" do
    article = build_article
    attach_string_thumbnail(article, filename: "bad.pdf", content_type: "application/pdf")

    assert_not article.valid?
    assert_includes article.errors[:thumbnail], thumbnail_content_type_error
    assert_includes article.errors[:thumbnail], thumbnail_extension_error
  end

  test "rejects gif thumbnail" do
    article = build_article
    attach_string_thumbnail(article, filename: "bad.gif", content_type: "image/gif")

    assert_not article.valid?
    assert_includes article.errors[:thumbnail], thumbnail_content_type_error
    assert_includes article.errors[:thumbnail], thumbnail_extension_error
  end

  test "rejects allowed mime type with invalid extension" do
    article = build_article
    attach_string_thumbnail(article, filename: "bad.txt", content_type: "image/png")

    assert_not article.valid?
    assert_includes article.errors[:thumbnail], thumbnail_extension_error
  end

  test "rejects invalid mime type with allowed extension" do
    article = build_article
    attach_string_thumbnail(article, filename: "bad.png", content_type: "text/html")

    assert_not article.valid?
    assert_includes article.errors[:thumbnail], thumbnail_content_type_error
  end

  test "allows thumbnail smaller than 5 megabytes" do
    article = build_article
    attach_sized_thumbnail(article, byte_size: Article::THUMBNAIL_MAX_BYTE_SIZE - 1)

    assert article.valid?
  end

  test "allows thumbnail exactly 5 megabytes" do
    article = build_article
    attach_sized_thumbnail(article, byte_size: Article::THUMBNAIL_MAX_BYTE_SIZE)

    assert article.valid?
  end

  test "rejects thumbnail larger than 5 megabytes" do
    article = build_article
    attach_sized_thumbnail(article, byte_size: Article::THUMBNAIL_MAX_BYTE_SIZE + 1)

    assert_not article.valid?
    assert_includes article.errors[:thumbnail], thumbnail_size_error
  end

  test "uses japanese thumbnail validation messages" do
    article = build_article
    attach_string_thumbnail(article, filename: "bad.svg", content_type: "image/svg+xml")

    assert_not article.valid?
    assert_includes article.errors.full_messages, "サムネイル画像はJPEG、PNG、WebP形式のみアップロードできます"
    assert_includes article.errors.full_messages, "サムネイル画像の拡張子が正しくありません"
  end

  test "does not save article when thumbnail validation fails" do
    article = build_article
    attach_string_thumbnail(article, filename: "bad.html", content_type: "text/html")

    assert_no_difference -> { Article.count } do
      assert_not article.save
    end
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

test "allows rich text body with at least 400 visible characters" do
  article = build_article(editor_type: "rich_text", body: "<h2>見出し</h2><p>#{'本文' * 200}</p>")

  assert article.valid?
end

test "rejects rich text body with fewer than 400 visible characters" do
  article = build_article(editor_type: "rich_text", body: "<h2>見出し</h2><p>短い本文</p><span style=\"font-size: 1.5rem; color: #2563EB;\"></span>")

  assert_not article.valid?
  assert_includes article.errors[:body], plain_text_length_error
end


  test "allows rich text visible text at maximum length" do
    article = build_article(editor_type: "rich_text", body: "<p>#{"あ" * Article::RICH_TEXT_TEXT_MAX_LENGTH}</p>")

    assert article.valid?
  end

  test "rejects rich text visible text exceeding maximum length" do
    article = build_article(editor_type: "rich_text", body: "<p>#{"あ" * (Article::RICH_TEXT_TEXT_MAX_LENGTH + 1)}</p>")

    assert_not article.valid?
    assert_includes article.errors.full_messages, "本文は表示上の本文を15,000文字以内で入力してください"
  end

  test "allows rich text html at maximum length" do
    visible = "本文" * 200
    padding_size = Article::RICH_TEXT_HTML_MAX_LENGTH - visible.length - "<p></p>".length
    article = build_article(editor_type: "rich_text", body: "<p>#{visible}#{" " * padding_size}</p>")

    assert_equal Article::RICH_TEXT_HTML_MAX_LENGTH, article.body.length
    assert article.valid?
  end

  test "rejects rich text html exceeding maximum length" do
    visible = "本文" * 200
    padding_size = Article::RICH_TEXT_HTML_MAX_LENGTH - visible.length - "<p></p>".length + 1
    article = build_article(editor_type: "rich_text", body: "<p>#{visible}#{" " * padding_size}</p>")

    assert_not article.valid?
    assert_includes article.errors.full_messages, "本文HTMLは60,000文字以内で入力してください"
  end

  test "keeps markdown source maximum separate from rich text html maximum" do
    article = build_article(body: "あ" * (Article::BODY_MAX_LENGTH + 1))

    assert_not article.valid?
    assert_includes article.errors.full_messages, "本文は15,000文字以内で入力してください"
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

    def attach_fixture_thumbnail(article, filename:, content_type:)
      article.thumbnail.attach(
        io: File.open(Rails.root.join("test/fixtures/files", filename.downcase.sub("photo", "sample"))),
        filename: filename,
        content_type: content_type
      )
    end

    def attach_string_thumbnail(article, filename:, content_type:, content: "thumbnail")
      article.thumbnail.attach(
        io: StringIO.new(content),
        filename: filename,
        content_type: content_type,
        identify: false
      )
    end

    def attach_sized_thumbnail(article, byte_size:)
      attach_string_thumbnail(
        article,
        filename: "large.jpg",
        content_type: "image/jpeg",
        content: "a" * byte_size
      )
    end

    def long_body
      "本文" * 200
    end

    def plain_text_length_error
      I18n.t("activerecord.errors.models.article.attributes.body.too_short_plain_text", count: Article::MINIMUM_BODY_PLAIN_TEXT_LENGTH)
    end

    def thumbnail_content_type_error
      I18n.t("activerecord.errors.models.article.attributes.thumbnail.invalid_content_type")
    end

    def thumbnail_extension_error
      I18n.t("activerecord.errors.models.article.attributes.thumbnail.invalid_extension")
    end

    def thumbnail_size_error
      I18n.t("activerecord.errors.models.article.attributes.thumbnail.file_too_large")
    end
end
