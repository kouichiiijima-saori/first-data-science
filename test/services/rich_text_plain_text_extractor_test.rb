require "test_helper"

class RichTextPlainTextExtractorTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test "extracts visible text from sanitized html" do
    text = RichTextPlainTextExtractor.extract("<h2>見出し</h2><p>本文 <strong>太字</strong></p>")

    assert_equal "見出し本文 太字", text
  end

  test "does not count dangerous script content" do
    text = RichTextPlainTextExtractor.extract("<script>alert(1)</script><p>安全</p>")

    assert_equal "安全", text
  end

  test "uses image alt text" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
      filename: "sample.png",
      content_type: "image/png"
    )
    html = %(<p>本文</p><img src="#{rails_blob_path(blob, only_path: true)}" alt="画像説明">)

    assert_equal "本文画像説明", RichTextPlainTextExtractor.extract(html)
  end

  test "handles nil and empty safely" do
    assert_equal "", RichTextPlainTextExtractor.extract(nil)
    assert_equal "", RichTextPlainTextExtractor.extract("")
  end
end
