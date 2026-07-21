require "test_helper"

class MarkdownPlainTextExtractorTest < ActiveSupport::TestCase
  test "removes markdown symbols" do
    text = MarkdownPlainTextExtractor.extract("# 見出し\n\n**太字** と *斜体*")

    assert_equal "見出し 太字 と 斜体", text
  end

  test "keeps heading text" do
    assert_equal "タイトル", MarkdownPlainTextExtractor.extract("## タイトル")
  end

  test "keeps link text" do
    assert_equal "Rails を学ぶ", MarkdownPlainTextExtractor.extract("[Rails](https://rubyonrails.org) を学ぶ")
  end

  test "does not keep url for link length" do
    text = MarkdownPlainTextExtractor.extract("[Rails](https://rubyonrails.org)")

    assert_equal "Rails", text
    assert_not_includes text, "https://rubyonrails.org"
  end

  test "removes bare urls" do
    assert_equal "参考", MarkdownPlainTextExtractor.extract("参考 https://example.com/path")
  end

  test "keeps code content" do
    text = MarkdownPlainTextExtractor.extract("```ruby\nputs 1\n```")

    assert_equal "puts 1", text
  end

  test "keeps table text" do
    text = MarkdownPlainTextExtractor.extract("| A | B |\n| - | - |\n| 1 | 2 |")

    assert_equal "A B 1 2", text
  end

  test "removes html tags" do
    text = MarkdownPlainTextExtractor.extract("<strong>重要</strong> 本文")

    assert_equal "重要 本文", text
  end

  test "normalizes whitespace" do
    text = MarkdownPlainTextExtractor.extract("本文\n\n\t 次の本文")

    assert_equal "本文 次の本文", text
  end

  test "counts japanese characters correctly" do
    text = MarkdownPlainTextExtractor.extract("あいう")

    assert_equal 3, text.length
  end

  test "keeps image alt text" do
    text = MarkdownPlainTextExtractor.extract("![代替テキスト](/rails/active_storage/blobs/key/file.png)")

    assert_equal "代替テキスト", text
  end

  test "handles nil and empty string safely" do
    assert_equal "", MarkdownPlainTextExtractor.extract(nil)
    assert_equal "", MarkdownPlainTextExtractor.extract("")
    assert_equal 0, MarkdownPlainTextExtractor.length(nil)
  end
end
