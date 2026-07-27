require "test_helper"

class RichTextSanitizerTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test "keeps allowed rich text tags and formatting" do
    html = %(<h2>見出し</h2><p><strong>太字</strong><em>斜体</em><u>下線</u></p><ul><li>項目</li></ul>)

    sanitized = RichTextSanitizer.sanitize(html)

    assert_includes sanitized, "<h2>見出し</h2>"
    assert_includes sanitized, "<strong>太字</strong>"
    assert_includes sanitized, "<em>斜体</em>"
    assert_includes sanitized, "<u>下線</u>"
    assert_includes sanitized, "<li>項目</li>"
  end

  test "removes dangerous tags and event attributes" do
    html = %(<p onclick="alert(1)">本文</p><script>alert(1)</script><iframe src="https://example.com"></iframe><div><script>alert(2)</script><span>安全</span></div>)

    sanitized = RichTextSanitizer.sanitize(html)

    assert_includes sanitized, "<p>本文</p>"
    assert_includes sanitized, "<span>安全</span>"
    assert_not_includes sanitized, "onclick"
    assert_not_includes sanitized, "script"
    assert_not_includes sanitized, "iframe"
    assert_not_includes sanitized, "alert(1)"
    assert_not_includes sanitized, "alert(2)"
  end

  test "converts body h1 to h2 and keeps h2 through h4" do
    sanitized = RichTextSanitizer.sanitize("<h1>大見出し</h1><h3>中見出し</h3><h4>小見出し</h4>")

    assert_includes sanitized, "<h2>大見出し</h2>"
    assert_includes sanitized, "<h3>中見出し</h3>"
    assert_includes sanitized, "<h4>小見出し</h4>"
    assert_not_includes sanitized, "<h1>"
  end

  test "keeps safe links and forces rel on target blank" do
    html = %(<a href="https://example.com" target="_blank" rel="opener">link</a><a href="/articles">internal</a>)

    sanitized = RichTextSanitizer.sanitize(html)

    assert_includes sanitized, %(href="https://example.com")
    assert_includes sanitized, %(target="_blank")
    assert_includes sanitized, %(rel="noopener noreferrer")
    assert_includes sanitized, %(href="/articles")
  end

  test "removes dangerous link hrefs" do
    html = %(<a href="javascript:alert(1)">js</a><a href="data:text/html,evil">data</a><a href="//example.com/path">proto</a><a href="mailto:test@example.com">mail</a>)

    sanitized = RichTextSanitizer.sanitize(html)

    assert_not_includes sanitized, "javascript:"
    assert_not_includes sanitized, "data:text/html"
    assert_not_includes sanitized, "//example.com"
    assert_not_includes sanitized, "mailto:"
  end

  test "keeps only configured font size and color styles" do
    html = %(<span style="font-size: 1.25rem; color: #2563eb; background-image: url(javascript:alert(1)); position: fixed">ok</span><span style="font-size: 99px; color: red">bad</span>)

    sanitized = RichTextSanitizer.sanitize(html)

    assert_includes sanitized, %(style="font-size: 1.25rem; color: #2563EB")
    assert_not_includes sanitized, "background-image"
    assert_not_includes sanitized, "position"
    assert_not_includes sanitized, "99px"
    assert_not_includes sanitized, "red"
  end

  test "keeps active storage image and normalizes dimensions" do
    blob = create_blob("sample.png", "image/png")
    url = rails_blob_path(blob, only_path: true)

    sanitized = RichTextSanitizer.sanitize(%(<img src="#{url}" alt="本文画像" width="320px" height="240">), allowed_blob_ids: [ blob.id ])

    assert_includes sanitized, %(src="#{url}")
    assert_includes sanitized, %(alt="本文画像")
    assert_includes sanitized, %(width="320")
    assert_includes sanitized, %(height="240")
  end

  test "removes images with external data or unowned active storage urls" do
    allowed_blob = create_blob("sample.png", "image/png")
    other_blob = create_blob("sample.jpg", "image/jpeg")
    other_url = rails_blob_path(other_blob, only_path: true)
    html = %(<img src="https://example.com/image.png"><img src="data:image/png;base64,AAA"><img src="#{other_url}">)

    sanitized = RichTextSanitizer.sanitize(html, allowed_blob_ids: [ allowed_blob.id ])

    assert_not_includes sanitized, "<img"
    assert_not_includes sanitized, "https://example.com"
    assert_not_includes sanitized, "data:image"
    assert_not_includes sanitized, other_url
  end

  test "removes invalid image dimensions and image styles" do
    blob = create_blob("sample.webp", "image/webp")
    url = rails_blob_path(blob, only_path: true)

    sanitized = RichTextSanitizer.sanitize(%(<img src="#{url}" width="0" height="99999" style="width: 10px">), allowed_blob_ids: [ blob.id ])

    assert_includes sanitized, %(src="#{url}")
    assert_not_includes sanitized, "width="
    assert_not_includes sanitized, "height="
    assert_not_includes sanitized, "style="
  end

  test "is idempotent" do
    blob = create_blob("sample.png", "image/png")
    html = %(<p onclick="evil()"><span style="color: #047857; font-size: 1rem; left: 0">本文</span><img src="#{rails_blob_path(blob, only_path: true)}" width="200px"></p>)

    once = RichTextSanitizer.sanitize(html, allowed_blob_ids: [ blob.id ])
    twice = RichTextSanitizer.sanitize(once, allowed_blob_ids: [ blob.id ])

    assert_equal once, twice
  end

  private
    def create_blob(filename, content_type)
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("test/fixtures/files", filename)),
        filename: filename,
        content_type: content_type
      )
    end
end
