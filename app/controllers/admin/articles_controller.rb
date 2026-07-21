class Admin::ArticlesController < Admin::BaseController
  before_action :set_article, only: %i[edit update destroy]

  def index
    @articles = Article.includes(:tags).order(updated_at: :desc, id: :desc)
  end

  def new
    @article = Article.new
    @tag_names = ""
  end

  def create
    @article = Article.new(article_params)

    if save_article_with_tags
      redirect_to admin_articles_path, notice: "記事を作成しました"
    else
      prepare_tag_names
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    prepare_tag_names
  end

  def update
    @article.assign_attributes(article_params)

    if save_article_with_tags
      redirect_to admin_articles_path, notice: "記事を更新しました"
    else
      prepare_tag_names
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @article.destroy
      redirect_to admin_articles_path, notice: "記事を削除しました"
    else
      redirect_to admin_articles_path, alert: "記事を削除できませんでした"
    end
  end

  private
    def set_article
      @article = Article.find(params[:id])
    end

    def article_params
      params.require(:article).permit(:title, :summary, :body, :status, :thumbnail)
    end

    def tag_names_param
      params.require(:article).permit(:tag_names)[:tag_names]
    end

    def save_article_with_tags
      Article.transaction do
        @article.save!
        assign_tags
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def assign_tags
      tags = normalized_tag_names.map { |name| Tag.find_or_create_by!(name: name) }
      @article.tags = tags
    end

    def normalized_tag_names
      tag_names_param.to_s.split(/[,\uFF0C]/).map(&:strip).reject(&:blank?).uniq
    end

    def prepare_tag_names
      @tag_names = tag_names_param.presence || @article.tags.map(&:name).join(", ")
    rescue ActionController::ParameterMissing
      @tag_names = @article.tags.map(&:name).join(", ")
    end
end
