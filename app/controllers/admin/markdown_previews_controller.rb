class Admin::MarkdownPreviewsController < Admin::BaseController
  def create
    if markdown_body.length > Article::BODY_MAX_LENGTH
      render json: { error: body_too_long_message }, status: :unprocessable_entity
    else
      render json: { html: MarkdownRenderer.render(markdown_body) }
    end
  end

  private
    def markdown_body
      params[:markdown].presence || params.dig(:article, :body).to_s
    end

    def body_too_long_message
      I18n.t("admin.markdown_previews.errors.body_too_long", count: Article::BODY_MAX_LENGTH.to_fs(:delimited))
    end
end
