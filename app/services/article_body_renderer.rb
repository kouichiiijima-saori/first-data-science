class ArticleBodyRenderer
  class << self
    def render(article)
      new(article).render
    end
  end

  def initialize(article)
    @article = article
  end

  def render
    return RichTextRenderer.render(article) if article.editor_type == "rich_text"

    MarkdownRenderer.render(article.body)
  end

  private
    attr_reader :article
end
