require "test_helper"
require "tempfile"

class ArticleBodyImageUploadTest < ActiveSupport::TestCase
  test "uploads valid image as active storage blob" do
    result = ArticleBodyImageUpload.call(uploaded_fixture("sample.jpg", "image/jpeg"))

    assert result.success?
    assert result.blob.persisted?
    assert_equal "image/jpeg", result.blob.content_type
    assert_equal "sample.jpg", result.blob.filename.to_s
  end

  test "normalizes filename" do
    result = ArticleBodyImageUpload.call(uploaded_fixture("sample.jpg", "image/jpeg", original_filename: "../bad name<script>.JPG"))

    assert result.success?
    assert_equal "..-bad name-script-.JPG", result.blob.filename.to_s
  end

  test "rejects content type spoofing" do
    result = upload_string("spoof.png", "image/png", "<html></html>")

    assert_not result.success?
    assert_includes result.errors, I18n.t("admin.article_images.errors.invalid_signature")
  end

  test "rejects invalid extension" do
    result = ArticleBodyImageUpload.call(uploaded_fixture("sample.png", "image/png", original_filename: "bad.txt"))

    assert_not result.success?
    assert_includes result.errors, I18n.t("admin.article_images.errors.invalid_extension")
  end

  test "validates existing blob metadata" do
    result = ArticleBodyImageUpload.call(uploaded_fixture("sample.webp", "image/webp"))

    assert ArticleBodyImageUpload.valid_blob?(result.blob)
  end

  private
    def uploaded_fixture(filename, content_type, original_filename: filename)
      Rack::Test::UploadedFile.new(
        Rails.root.join("test/fixtures/files", filename),
        content_type,
        false,
        original_filename: original_filename
      )
    end

    def upload_string(filename, content_type, content)
      Tempfile.create([ File.basename(filename, ".*"), File.extname(filename) ], binmode: true) do |file|
        file.write(content)
        file.rewind

        return ArticleBodyImageUpload.call(
          Rack::Test::UploadedFile.new(file.path, content_type, true, original_filename: filename)
        )
      end
    end
end
