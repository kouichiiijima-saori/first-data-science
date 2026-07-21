class ArticlesController < ApplicationController
  def index
    @articles = Article.published
      .includes(:tags)
      .with_attached_thumbnail
      .order(created_at: :desc, id: :desc)
  end

  def show
    @article = Article.published.includes(:tags).with_attached_thumbnail.find(params[:id])
    @rendered_body_html = MarkdownRenderer.render(@article.body)
  end
end
