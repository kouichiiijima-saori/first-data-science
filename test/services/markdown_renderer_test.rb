require "test_helper"

class MarkdownRendererTest < ActiveSupport::TestCase
  test "converts heading" do
    html = MarkdownRenderer.render("# 見出し")

    assert_includes html, "<h1>見出し</h1>"
  end

  test "converts paragraph" do
    html = MarkdownRenderer.render("本文です。")

    assert_includes html, "<p>本文です。</p>"
  end

  test "converts list" do
    html = MarkdownRenderer.render("- Python\n- 統計")

    assert_includes html, "<ul>"
    assert_includes html, "<li>Python</li>"
    assert_includes html, "<li>統計</li>"
  end

  test "converts link" do
    html = MarkdownRenderer.render("[Rails](https://rubyonrails.org)")

    assert_includes html, '<a href="https://rubyonrails.org">Rails</a>'
  end

  test "converts blockquote" do
    html = MarkdownRenderer.render("> 引用")

    assert_includes html, "<blockquote>"
    assert_includes html, "<p>引用</p>"
  end

  test "converts inline code" do
    html = MarkdownRenderer.render("`code` を読む")

    assert_includes html, "<code>code</code>"
  end

  test "converts fenced code block" do
    html = MarkdownRenderer.render("```ruby\nputs 1\n```")

    assert_includes html, '<pre><code class="language-ruby">puts 1'
    assert_not_includes html, "style="
  end

  test "converts table" do
    html = MarkdownRenderer.render("| A | B |\n| - | - |\n| 1 | 2 |")

    assert_includes html, "<table>"
    assert_includes html, "<th>A</th>"
    assert_includes html, "<td>1</td>"
  end

  test "converts safe image syntax" do
    html = MarkdownRenderer.render("![サムネイル](/rails/active_storage/blobs/key/file.png)")

    assert_includes html, '<img src="/rails/active_storage/blobs/key/file.png" alt="サムネイル">'
  end

  test "handles empty string safely" do
    assert_equal "", MarkdownRenderer.render("")
    assert_equal "", MarkdownRenderer.render(nil)
  end

  test "handles japanese body" do
    html = MarkdownRenderer.render("データサイエンスを学びます。")

    assert_includes html, "データサイエンスを学びます。"
  end

  test "removes script tag" do
    html = MarkdownRenderer.render("<script>alert('x')</script>")

    assert_not_includes html, "<script"
  end

  test "removes iframe" do
    html = MarkdownRenderer.render('<iframe src="https://example.com"></iframe>本文')

    assert_not_includes html, "<iframe"
  end

  test "removes event handler attributes" do
    html = MarkdownRenderer.render('<a href="/articles" onclick="evil()">記事</a>')

    assert_not_includes html, "onclick"
  end

  test "removes javascript url from links" do
    html = MarkdownRenderer.render("[bad](javascript:alert(1))")

    assert_not_includes html, "javascript:"
    assert_not_includes html, 'href="javascript'
    assert_includes html, ">bad</a>"
  end

  test "rejects dangerous image url" do
    html = MarkdownRenderer.render("![bad](data:image/png;base64,AAAA)")

    assert_not_includes html, "<img"
    assert_not_includes html, "data:image"
  end

  test "keeps allowed tags and attributes" do
    html = MarkdownRenderer.render("[Rails](https://rubyonrails.org \"Ruby on Rails\")\n\n**太字**")

    assert_includes html, '<a href="https://rubyonrails.org" title="Ruby on Rails">Rails</a>'
    assert_includes html, "<strong>太字</strong>"
  end

  test "keeps only code language class" do
    html = MarkdownRenderer.render("```ruby\nputs 1\n```")

    assert_includes html, 'class="language-ruby"'
    assert_not_includes html, "<span"
    assert_not_includes html, "style="
  end

  test "handles raw html safely" do
    html = MarkdownRenderer.render('<form action="/danger"><button>send</button></form>本文')

    assert_not_includes html, "<form"
    assert_not_includes html, "<button"
  end

  test "does not double escape entities" do
    html = MarkdownRenderer.render("Tom & Jerry")

    assert_includes html, "Tom &amp; Jerry"
    assert_not_includes html, "&amp;amp;"
  end
end
