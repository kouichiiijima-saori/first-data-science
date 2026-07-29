require "test_helper"

class ArticleBodyImageLifecycleTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
  end

  test "detaches body_images attachment and enqueues blob purge when image tag is removed on article update" do
    blob = create_body_image_blob("sample.png")
    image_url = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
    body_with_image = %(<h2>見出し</h2><p>#{'本文' * 200}</p><img src="#{image_url}" width="320">)

    article = Article.create!(
      title: "Image Removal Lifecycle Test",
      summary: "Testing image lifecycle on update",
      body: body_with_image,
      status: "draft",
      editor_type: "rich_text"
    )
    article.body_images.attach(blob)

    assert_equal 1, article.body_images.count
    assert_equal 1, article.body_images.blobs.count
    assert ActiveStorage::Blob.exists?(blob.id)

    body_without_image = %(<h2>見出し</h2><p>#{'本文' * 200}のみ更新</p>)
    article.update!(body: body_without_image)

    perform_enqueued_jobs do
      result = ArticleBodyImageSynchronizer.call(article)
      assert_equal 1, result[:detached_count]
      assert_equal 1, result[:purged_count]
    end

    article.reload
    assert_not_includes article.body, "<img"
    assert_equal 0, article.body_images.count
    assert_not ActiveStorage::Blob.exists?(blob.id)
  end

  test "purges body_images attachments and blobs when article is destroyed" do
    blob = create_body_image_blob("sample.png")

    article = Article.create!(
      title: "Article Destroy Lifecycle Test",
      summary: "Testing image lifecycle on article destroy",
      body: "<h2>見出し</h2><p>#{'本文' * 200}</p>",
      status: "draft",
      editor_type: "rich_text"
    )
    article.body_images.attach(blob)

    blob_id = blob.id

    assert ActiveStorage::Blob.exists?(blob_id)

    perform_enqueued_jobs do
      article.destroy!
    end

    assert_not Article.exists?(article.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
  end

  test "creates unattached blob when image is uploaded but form is abandoned" do
    upload_file = Rack::Test::UploadedFile.new(
      Rails.root.join("test/fixtures/files/sample.png"),
      "image/png"
    )

    result = ArticleBodyImageUpload.call(upload_file)
    assert result.success?
    uploaded_blob = result.blob

    # When form is abandoned, blob remains unattached to any record
    assert_includes ActiveStorage::Blob.unattached, uploaded_blob
    assert_equal 0, uploaded_blob.attachments.count
    assert ActiveStorage::Blob.exists?(uploaded_blob.id)
    assert uploaded_blob.service.exist?(uploaded_blob.key)
  end

  test "preserves uploaded blob for attachment when validation fails and form is retried" do
    upload_file = Rack::Test::UploadedFile.new(
      Rails.root.join("test/fixtures/files/sample.png"),
      "image/png"
    )
    result = ArticleBodyImageUpload.call(upload_file)
    uploaded_blob = result.blob

    invalid_article = Article.new(
      title: "", # invalid title
      summary: "Summary",
      body: "<h2>見出し</h2><p>#{'本文' * 200}</p>",
      status: "draft",
      editor_type: "rich_text"
    )

    assert_not invalid_article.valid?
    assert ActiveStorage::Blob.exists?(uploaded_blob.id)

    # Validated & fixed retry
    invalid_article.title = "Valid Fixed Title"
    assert invalid_article.save
    invalid_article.body_images.attach(uploaded_blob)

    assert_equal 1, invalid_article.body_images.count
    assert_includes invalid_article.body_images.blobs, uploaded_blob
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
