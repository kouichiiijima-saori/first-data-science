class Article < ApplicationRecord
  STATUSES = %w[draft published].freeze
  MINIMUM_BODY_PLAIN_TEXT_LENGTH = 400

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_one_attached :thumbnail

  validates :title, presence: true
  validates :body, presence: true
  validates :summary, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :body_plain_text_length

  private
    def body_plain_text_length
      return if body.blank?

      if MarkdownPlainTextExtractor.length(body) < MINIMUM_BODY_PLAIN_TEXT_LENGTH
        errors.add(:body, "must be at least #{MINIMUM_BODY_PLAIN_TEXT_LENGTH} plain text characters")
      end
    rescue StandardError
      errors.add(:body, "could not be validated")
    end
end
