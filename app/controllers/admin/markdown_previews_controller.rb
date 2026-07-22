class Admin::MarkdownPreviewsController < Admin::BaseController
  def create
    render json: { html: MarkdownRenderer.render(markdown_body) }
  end

  private
    def markdown_body
      params[:markdown].presence || params.dig(:article, :body).to_s
    end
end
