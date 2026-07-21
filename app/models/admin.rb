class Admin < ApplicationRecord
  has_secure_password

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 255 }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password_digest, presence: true

  private
    def normalize_email
      self.email = email.to_s.strip.downcase
    end
end
