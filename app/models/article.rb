class Article < ApplicationRecord
  STATUSES = %w[draft published].freeze
  MINIMUM_BODY_PLAIN_TEXT_LENGTH = 400
  THUMBNAIL_ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  THUMBNAIL_ALLOWED_EXTENSIONS = %w[jpg jpeg png webp].freeze
  THUMBNAIL_MAX_BYTE_SIZE = 5.megabytes

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_one_attached :thumbnail

  scope :published, -> { where(status: "published") }

  validates :title, presence: true
  validates :body, presence: true
  validates :summary, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :body_plain_text_length
  validate :thumbnail_file

  private
    def body_plain_text_length
      return if body.blank?

      if MarkdownPlainTextExtractor.length(body) < MINIMUM_BODY_PLAIN_TEXT_LENGTH
        errors.add(:body, "must be at least #{MINIMUM_BODY_PLAIN_TEXT_LENGTH} plain text characters")
      end
    rescue StandardError
      errors.add(:body, "could not be validated")
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
