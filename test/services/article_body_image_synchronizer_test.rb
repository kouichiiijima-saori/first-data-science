require "test_helper"

class ArticleBodyImageSynchronizerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @blob1 = create_body_image_blob("sample.png")
    @blob2 = create_body_image_blob("sample.png")
    @url1 = Rails.application.routes.url_helpers.rails_blob_path(@blob1, only_path: true)
    @url2 = Rails.application.routes.url_helpers.rails_blob_path(@blob2, only_path: true)
  end

  test "detaches unreferenced attachment and purges blob when image tag is removed from rich text body" do
    body_with_images = %(<h2>見出し</h2><p>#{'本文' * 200}</p><img src="#{@url1}"><img src="#{@url2}">)
    article = Article.create!(
      title: "Sync Test 1",
      summary: "Summary text",
      body: body_with_images,
      status: "draft",
      editor_type: "rich_text"
    )
    article.body_images.attach([ @blob1, @blob2 ])

    assert_equal 2, article.body_images.count

    # Remove @blob2 from body
    article.update!(body: %(<h2>見出し</h2><p>#{'本文' * 200}</p><img src="#{@url1}">))

    perform_enqueued_jobs do
      result = ArticleBodyImageSynchronizer.call(article)
      assert_equal 1, result[:detached_count]
      assert_equal 1, result[:purged_count]
      assert_equal 0, result[:errors_count]
    end

    article.reload
    assert_equal 1, article.body_images.count
    assert_includes article.body_images.blobs, @blob1
    assert ActiveStorage::Blob.exists?(@blob1.id)
    assert_not ActiveStorage::Blob.exists?(@blob2.id)
  end

  test "detaches attachment but does not purge blob if blob is referenced by another article" do
    body1 = %(<h2>見出し</h2><p>#{'本文' * 200}</p><img src="#{@url1}">)
    article1 = Article.create!(
      title: "Article 1",
      summary: "Summary text",
      body: body1,
      status: "draft",
      editor_type: "rich_text"
    )
    article1.body_images.attach(@blob1)

    article2 = Article.create!(
      title: "Article 2",
      summary: "Summary text",
      body: body1,
      status: "draft",
      editor_type: "rich_text"
    )
    article2.body_images.attach(@blob1)

    # Remove @blob1 from article1 only
    article1.update!(body: %(<h2>見出し</h2><p>#{'本文' * 200}</p>))

    perform_enqueued_jobs do
      result = ArticleBodyImageSynchronizer.call(article1)
      assert_equal 1, result[:detached_count]
      assert_equal 0, result[:purged_count] # blob1 is still attached to article2
    end

    article1.reload
    assert_equal 0, article1.body_images.count
    assert ActiveStorage::Blob.exists?(@blob1.id)
    assert_equal 1, article2.body_images.count
  end

  test "keeps attachment intact when same image appears multiple times in body" do
    body_duplicate = %(<h2>見出し</h2><p>#{'本文' * 200}</p><img src="#{@url1}"><p>再表示</p><img src="#{@url1}">)
    article = Article.create!(
      title: "Duplicate Image Test",
      summary: "Summary text",
      body: body_duplicate,
      status: "draft",
      editor_type: "rich_text"
    )
    article.body_images.attach(@blob1)

    result = ArticleBodyImageSynchronizer.call(article)
    assert_equal 0, result[:detached_count]
    assert_equal 0, result[:purged_count]
    assert_equal 1, article.body_images.count
  end

  test "skips synchronization for markdown articles" do
    body_markdown = %(## 見出し\n\n#{'本文' * 200}\n\n![alt](#{@url1}))
    article = Article.create!(
      title: "Markdown Sync Test",
      summary: "Summary text",
      body: body_markdown,
      status: "draft",
      editor_type: "markdown"
    )
    article.body_images.attach(@blob1)

    # Update body without image markdown
    article.update!(body: %(## 見出し\n\n#{'本文' * 200}))

    result = ArticleBodyImageSynchronizer.call(article)
    assert_equal 0, result[:detached_count]
    assert_equal 0, result[:purged_count]
    assert_equal 1, article.body_images.count
    assert ActiveStorage::Blob.exists?(@blob1.id)
  end

  test "handles malformed HTML without raising exception" do
    malformed_body = %(<h2>見出し</h2><p>#{'本文' * 200}</p><img src="#{@url1}" unclosed tag <<>>>)
    article = Article.create!(
      title: "Malformed HTML Test",
      summary: "Summary text",
      body: malformed_body,
      status: "draft",
      editor_type: "rich_text"
    )
    article.body_images.attach(@blob1)

    assert_nothing_raised do
      result = ArticleBodyImageSynchronizer.call(article)
      assert_equal 0, result[:errors_count]
    end
  end

  private
    def create_body_image_blob(filename)
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("test/fixtures/files", filename)),
        filename: filename,
        content_type: "image/png"
      )
    end
end
