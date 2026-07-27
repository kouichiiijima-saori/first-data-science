class RichTextPlainTextExtractor
  class << self
    def extract(html)
      new(html).extract
    end

    def length(html)
      extract(html).length
    end
  end

  def initialize(html)
    @html = html.to_s
  end

  def extract
    sanitized_html = RichTextSanitizer.sanitize(html)
    fragment = Nokogiri::HTML5.fragment(sanitized_html)
    fragment.css("img").each do |image|
      image.replace(image["alt"].to_s)
    end
    ActionView::Base.full_sanitizer.sanitize(fragment.to_html).gsub(/[[:space:]]+/, " ").strip
  rescue ArgumentError, TypeError, Nokogiri::XML::SyntaxError
    ""
  end

  private
    attr_reader :html
end
