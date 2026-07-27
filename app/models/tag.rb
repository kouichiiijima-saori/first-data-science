class Tag < ApplicationRecord
  NAME_MAX_LENGTH = 50

  has_many :article_tags, dependent: :destroy
  has_many :articles, through: :article_tags

  before_validation :normalize_name

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: NAME_MAX_LENGTH }

  private
    def normalize_name
      self.name = name.to_s.strip
    end
end
