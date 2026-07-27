class Admin::ArticlesController < Admin::BaseController
  before_action :set_article, only: %i[edit update destroy]

  def index
    @articles = Article.includes(:tags).order(updated_at: :desc, id: :desc)
  end

  def new
    @article = Article.new
    @tag_names = ""
    @body_image_signed_ids = []
  end

  def create
    @article = Article.new(article_params)

    if save_article_with_tags
      redirect_to admin_articles_path, notice: "記事を作成しました"
    else
      prepare_tag_names
      prepare_body_image_signed_ids
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    prepare_tag_names
    prepare_body_image_signed_ids
  end

  def update
    @article.assign_attributes(article_params)

    if save_article_with_tags
      redirect_to admin_articles_path, notice: "記事を更新しました"
    else
      restore_locked_editor_type
      prepare_tag_names
      prepare_body_image_signed_ids
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
      params.require(:article).permit(:title, :summary, :body, :status, :editor_type, :thumbnail)
    end

    def tag_names_param
      params.require(:article).permit(:tag_names)[:tag_names]
    end

    def save_article_with_tags
      tag_names = normalized_tag_names
      body_image_signed_ids = normalized_body_image_signed_ids
      article_valid = @article.valid?
      tag_names_valid = validate_tag_names(tag_names)
      body_images_valid = validate_body_image_signed_ids(body_image_signed_ids)
      return false unless article_valid && tag_names_valid && body_images_valid

      Article.transaction do
        @article.save!
        assign_tags(tag_names)
        attach_body_images(body_image_signed_ids)
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def validate_tag_names(tag_names)
      valid = true

      if tag_names.size > Article::MAX_TAGS_PER_ARTICLE
        @article.errors.add(:base, I18n.t("admin.articles.errors.too_many_tags", count: Article::MAX_TAGS_PER_ARTICLE))
        valid = false
      end

      if tag_names.any? { |name| name.length > Tag::NAME_MAX_LENGTH }
        @article.errors.add(:base, I18n.t("admin.articles.errors.tag_name_too_long", count: Tag::NAME_MAX_LENGTH))
        valid = false
      end

      valid
    end

    def validate_body_image_signed_ids(signed_ids)
      return true unless @article.editor_type == "rich_text"

      signed_ids.all? do |signed_id|
        blob = ActiveStorage::Blob.find_signed(signed_id)
        valid = blob.present? && ArticleBodyImageUpload.valid_blob?(blob)
        @article.errors.add(:base, I18n.t("admin.article_images.errors.upload_failed")) unless valid
        valid
      end
    end

    def attach_body_images(signed_ids)
      return unless @article.editor_type == "rich_text"
      return if signed_ids.empty?

      existing_blob_ids = @article.body_images.blobs.pluck(:id)
      blobs = signed_ids.filter_map { |signed_id| ActiveStorage::Blob.find_signed(signed_id) }
      new_blobs = blobs.uniq.reject { |blob| existing_blob_ids.include?(blob.id) }
      @article.body_images.attach(new_blobs) if new_blobs.any?
    end

    def restore_locked_editor_type
      return unless @article.persisted? && @article.will_save_change_to_editor_type?

      @article.editor_type = @article.editor_type_in_database
    end

    def assign_tags(tag_names)
      tags = tag_names.map { |name| Tag.find_or_create_by!(name: name) }
      @article.tags = tags
    end

    def normalized_tag_names
      tag_names_param.to_s.split(/[,\uFF0C]/).map(&:strip).reject(&:blank?).uniq
    end

    def normalized_body_image_signed_ids
      return [] unless @article.editor_type == "rich_text"

      Array.wrap(body_image_signed_ids_param).map(&:to_s).map(&:strip).reject(&:blank?).uniq
    end

    def body_image_signed_ids_param
      params.require(:article).permit(body_image_signed_ids: [])[:body_image_signed_ids]
    rescue ActionController::ParameterMissing
      []
    end

    def prepare_body_image_signed_ids
      @body_image_signed_ids = normalized_body_image_signed_ids
      @body_image_signed_ids = @article.body_images.blobs.map(&:signed_id) if @body_image_signed_ids.empty?
    end

    def prepare_tag_names
      @tag_names = tag_names_param.presence || @article.tags.map(&:name).join(", ")
    rescue ActionController::ParameterMissing
      @tag_names = @article.tags.map(&:name).join(", ")
    end
end
