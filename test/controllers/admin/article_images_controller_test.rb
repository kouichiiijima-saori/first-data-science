require "test_helper"
require "tempfile"

class Admin::ArticleImagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = Admin.create!(email: "admin@example.com", password: "password123")
  end

  test "authenticated admin uploads jpeg body image" do
    login_as_admin

    assert_difference -> { ActiveStorage::Blob.count }, 1 do
      post admin_article_images_path, params: { image: uploaded_fixture("sample.jpg", "image/jpeg") }
    end

    assert_response :created
    json = response.parsed_body
    blob = ActiveStorage::Blob.order(:created_at).last
    assert_equal true, json["success"]
    assert_match %r{\A/rails/active_storage/blobs/}, json["url"]
    assert_no_match %r{\Ahttps?://}, json["url"]
    assert_equal blob.signed_id, json["signed_id"]
    assert_equal "sample.jpg", json["filename"]
    assert_equal "image/jpeg", json["content_type"]
    assert_equal [ json["url"] ], json.dig("data", "files")
    assert_equal "", json.dig("data", "baseurl")
    assert_no_match %r{\Ahttps?://}, json.dig("data", "files").first
    assert_equal [ true ], json.dig("data", "isImages")
    assert_equal [ blob.signed_id ], json.dig("data", "signed_ids")
  end

  test "authenticated admin uploads png body image" do
    login_as_admin

    assert_difference -> { ActiveStorage::Blob.count }, 1 do
      post admin_article_images_path, params: { image: uploaded_fixture("sample.png", "image/png") }
    end

    assert_response :created
    assert_equal "image/png", response.parsed_body["content_type"]
  end

  test "authenticated admin uploads webp body image" do
    login_as_admin

    assert_difference -> { ActiveStorage::Blob.count }, 1 do
      post admin_article_images_path, params: { image: uploaded_fixture("sample.webp", "image/webp") }
    end

    assert_response :created
    assert_equal "image/webp", response.parsed_body["content_type"]
  end

  test "unauthenticated upload is rejected" do
    assert_no_difference -> { ActiveStorage::Blob.count } do
      post admin_article_images_path, params: { image: uploaded_fixture("sample.jpg", "image/jpeg") }
    end

    assert_response :unauthorized
    assert_equal false, response.parsed_body["success"]
    assert_equal "ログインしてください", response.parsed_body["error"]
  end

  test "rejects svg body image" do
    assert_upload_rejected("bad.svg", "image/svg+xml", "<svg></svg>", /JPEG、PNG、WebP形式/)
  end

  test "rejects gif body image" do
    assert_upload_rejected("bad.gif", "image/gif", "GIF89a", /JPEG、PNG、WebP形式/)
  end

  test "rejects pdf body image" do
    assert_upload_rejected("bad.pdf", "application/pdf", "%PDF-1.7", /JPEG、PNG、WebP形式/)
  end

  test "rejects html body image" do
    assert_upload_rejected("bad.html", "text/html", "<html></html>", /JPEG、PNG、WebP形式/)
  end

  test "rejects mime spoofing" do
    assert_upload_rejected("spoof.png", "image/png", "<html></html>", /内容が画像形式と一致しません/)
  end

  test "rejects extension spoofing" do
    login_as_admin

    assert_no_difference -> { ActiveStorage::Blob.count } do
      post admin_article_images_path, params: { image: uploaded_fixture("sample.png", "image/png", original_filename: "bad.txt") }
    end

    assert_response :unprocessable_entity
    assert_match(/拡張子が正しくありません/, response.parsed_body["error"])
  end

  test "rejects oversized body image" do
    login_as_admin

    assert_no_difference -> { ActiveStorage::Blob.count } do
      with_upload("large.jpg", "image/jpeg", oversized_jpeg) do |upload|
        post admin_article_images_path, params: { image: upload }
      end
    end

    assert_response :unprocessable_entity
    assert_match(/5MB以下/, response.parsed_body["error"])
  end

  test "rejects empty body image" do
    assert_upload_rejected("empty.jpg", "image/jpeg", "", /空です/)
  end

  private
    def login_as_admin
      post admin_login_path, params: { email: @admin.email, password: "password123" }
    end

    def uploaded_fixture(filename, content_type, original_filename: filename)
      Rack::Test::UploadedFile.new(
        Rails.root.join("test/fixtures/files", filename),
        content_type,
        false,
        original_filename: original_filename
      )
    end

    def assert_upload_rejected(filename, content_type, content, error_pattern)
      login_as_admin

      assert_no_difference -> { ActiveStorage::Blob.count } do
        with_upload(filename, content_type, content) do |upload|
          post admin_article_images_path, params: { image: upload }
        end
      end

      assert_response :unprocessable_entity
      assert_equal false, response.parsed_body["success"]
      assert_match error_pattern, response.parsed_body["error"]
      assert_match error_pattern, response.parsed_body.dig("data", "messages").join(" ")
    end

    def with_upload(filename, content_type, content)
      Tempfile.create([ File.basename(filename, ".*"), File.extname(filename) ], binmode: true) do |file|
        file.write(content)
        file.rewind

        yield Rack::Test::UploadedFile.new(
          file.path,
          content_type,
          true,
          original_filename: filename
        )
      end
    end

    def oversized_jpeg
      jpeg = File.binread(Rails.root.join("test/fixtures/files/sample.jpg"))
      jpeg + ("a" * (Article::BODY_IMAGE_MAX_BYTE_SIZE + 1 - jpeg.bytesize))
    end
end
