class User < ApplicationRecord
  has_secure_password
  has_many :votes, dependent: :destroy

  has_many :audiences, dependent: :destroy
  has_many :rounds, foreign_key: 'owner_id'

  validates :username, presence: true,
    uniqueness: { case_sensitive: false }

  enum :user_role, [:admin, :member]

  def owner?(round)
    rounds.include?(round)
  end

  def audience?(round)
    round.audiences.exists?(user: self)
  end
end
