class RichTextRenderer
  class << self
    def render(article_or_html)
      new(article_or_html).render
    end
  end

  def initialize(article_or_html)
    @article_or_html = article_or_html
  end

  def render
    RichTextSanitizer.sanitize(html, allowed_blob_ids: allowed_blob_ids).html_safe
  end

  private
    attr_reader :article_or_html

    def html
      article? ? article_or_html.body.to_s : article_or_html.to_s
    end

    def allowed_blob_ids
      return nil unless article?

      article_or_html.body_images.blobs.pluck(:id)
    end

    def article?
      article_or_html.is_a?(Article)
    end
end
