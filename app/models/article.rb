class Article < ApplicationRecord
  STATUSES = %w[draft published].freeze
  EDITOR_TYPES = %w[markdown rich_text].freeze
  DEFAULT_EDITOR_TYPE = "markdown"
  MINIMUM_BODY_PLAIN_TEXT_LENGTH = 400
  TITLE_MAX_LENGTH = 120
  SUMMARY_MAX_LENGTH = 500
  BODY_MAX_LENGTH = 15_000
  MAX_TAGS_PER_ARTICLE = 10
  TAG_NAMES_MAX_LENGTH = Tag::NAME_MAX_LENGTH * MAX_TAGS_PER_ARTICLE + ((MAX_TAGS_PER_ARTICLE - 1) * 2)
  THUMBNAIL_ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  THUMBNAIL_ALLOWED_EXTENSIONS = %w[jpg jpeg png webp].freeze
  THUMBNAIL_MAX_BYTE_SIZE = 5.megabytes
  BODY_IMAGE_ALLOWED_CONTENT_TYPES = THUMBNAIL_ALLOWED_CONTENT_TYPES
  BODY_IMAGE_ALLOWED_EXTENSIONS = THUMBNAIL_ALLOWED_EXTENSIONS
  BODY_IMAGE_MAX_BYTE_SIZE = THUMBNAIL_MAX_BYTE_SIZE

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_one_attached :thumbnail
  has_many_attached :body_images, dependent: :purge_later

  scope :published, -> { where(status: "published") }

  validates :title, presence: true, length: { maximum: TITLE_MAX_LENGTH }
  validates :body, presence: true, length: { maximum: BODY_MAX_LENGTH }
  validates :summary, presence: true, length: { maximum: SUMMARY_MAX_LENGTH }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :editor_type, presence: true, inclusion: { in: EDITOR_TYPES }
  validate :body_plain_text_length
  validate :thumbnail_file
  validate :editor_type_unchanged_after_create, on: :update

  def self.editor_type_options
    EDITOR_TYPES.map { |type| [ I18n.t("articles.editor_types.#{type}"), type ] }
  end

  private
    def body_plain_text_length
      return if body.blank?

      if body_plain_text_length_value < MINIMUM_BODY_PLAIN_TEXT_LENGTH
        errors.add(:body, :too_short_plain_text, count: MINIMUM_BODY_PLAIN_TEXT_LENGTH)
      end
    rescue StandardError
      errors.add(:body, :plain_text_validation_failed)
    end

    def body_plain_text_length_value
      return rich_text_plain_text.length if editor_type == "rich_text"

      MarkdownPlainTextExtractor.length(body)
    end

    def rich_text_plain_text
      ActionView::Base.full_sanitizer.sanitize(body.to_s).gsub(/[[:space:]]+/, " ").strip
    end

    def editor_type_unchanged_after_create
      return unless will_save_change_to_editor_type?

      errors.add(:editor_type, :cannot_change_after_create)
    end

    def thumbnail_file
      return unless thumbnail.attached?

      validate_thumbnail_content_type
      validate_thumbnail_extension
      validate_thumbnail_byte_size
    end

    def validate_thumbnail_content_type
      return if THUMBNAIL_ALLOWED_CONTENT_TYPES.include?(thumbnail.blob.content_type.to_s.downcase)

      errors.add(:thumbnail, :invalid_content_type)
    end

    def validate_thumbnail_extension
      extension = thumbnail.blob.filename.extension_without_delimiter.to_s.downcase
      return if THUMBNAIL_ALLOWED_EXTENSIONS.include?(extension)

      errors.add(:thumbnail, :invalid_extension)
    end

    def validate_thumbnail_byte_size
      return if thumbnail.blob.byte_size <= THUMBNAIL_MAX_BYTE_SIZE

      errors.add(:thumbnail, :file_too_large)
    end
end
