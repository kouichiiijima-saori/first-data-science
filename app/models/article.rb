class Article < ApplicationRecord
  STATUSES = %w[draft published].freeze

  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_one_attached :thumbnail

  validates :title, presence: true
  validates :body, presence: true
  validates :summary, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
end
