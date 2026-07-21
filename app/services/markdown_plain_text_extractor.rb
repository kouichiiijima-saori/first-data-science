require "commonmarker"

class MarkdownPlainTextExtractor
  OPTIONS = MarkdownRenderer::OPTIONS
  PLUGINS = MarkdownRenderer::PLUGINS
  IMAGE_MARKDOWN_PATTERN = /!\[([^\]]*)\]\((?:[^()\\]|\\.)*\)/
  STANDALONE_URL_PATTERN = %r{\b(?:https?://|www\.)\S+}i
  MARKDOWN_SYMBOL_RUN_PATTERN = /[#*_`~>\[\]()!|]{2,}/

  class << self
    def extract(markdown)
      new.extract(markdown)
    end

    def length(markdown)
      extract(markdown).length
    end
  end

  def extract(markdown)
    source = markdown.to_s.encode("UTF-8")
    return "" if source.blank?

    html = Commonmarker.to_html(image_alt_as_text(source), options: OPTIONS, plugins: PLUGINS)
    text = ActionView::Base.full_sanitizer.sanitize(html)
    text = text.gsub(STANDALONE_URL_PATTERN, " ")
    text = text.gsub(MARKDOWN_SYMBOL_RUN_PATTERN, " ")
    text.gsub(/[[:space:]]+/, " ").strip
  rescue ArgumentError, TypeError
    ""
  end

  private
    def image_alt_as_text(markdown)
      markdown.gsub(IMAGE_MARKDOWN_PATTERN) { ::Regexp.last_match(1) }
    end
end
