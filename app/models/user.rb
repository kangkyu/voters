class User < ApplicationRecord
  has_secure_password
  has_many :votes, dependent: :destroy

  has_many :audiences, dependent: :destroy
  has_many :rounds, foreign_key: "owner_id"

  validates :username, presence: true,
    uniqueness: { case_sensitive: false }

  enum :user_role, [:admin, :member]

  # nil until chosen: then the browser's language is used
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, allow_nil: true

  def owner?(round)
    round.present? && round.owner_id == id
  end

  def audience?(round)
    round.audiences.exists?(user: self)
  end
end
