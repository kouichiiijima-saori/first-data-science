class Article < ApplicationRecord
  STATUSES = %w[draft published].freeze
  MINIMUM_BODY_PLAIN_TEXT_LENGTH = 400
  TITLE_MAX_LENGTH = 120
  SUMMARY_MAX_LENGTH = 500
  BODY_MAX_LENGTH = 15_000
  MAX_TAGS_PER_ARTICLE = 10
  TAG_NAMES_MAX_LENGTH = Tag::NAME_MAX_LENGTH * MAX_TAGS_PER_ARTICLE + ((MAX_TAGS_PER_ARTICLE - 1) * 2)
  THUMBNAIL_ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  THUMBNAIL_ALLOWED_EXTENSIONS = %w[jpg jpeg png webp].freeze
  THUMBNAIL_MAX_BYTE_SIZE = 5.megabytes

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_one_attached :thumbnail

  scope :published, -> { where(status: "published") }

  validates :title, presence: true, length: { maximum: TITLE_MAX_LENGTH }
  validates :body, presence: true, length: { maximum: BODY_MAX_LENGTH }
  validates :summary, presence: true, length: { maximum: SUMMARY_MAX_LENGTH }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :body_plain_text_length
  validate :thumbnail_file

  private
    def body_plain_text_length
      return if body.blank?

      if MarkdownPlainTextExtractor.length(body) < MINIMUM_BODY_PLAIN_TEXT_LENGTH
        errors.add(:body, :too_short_plain_text, count: MINIMUM_BODY_PLAIN_TEXT_LENGTH)
      end
    rescue StandardError
      errors.add(:body, :plain_text_validation_failed)
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
