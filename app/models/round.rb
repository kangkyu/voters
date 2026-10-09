class Round < ApplicationRecord
  include Rails.application.routes.url_helpers

  has_many :audiences, dependent: :destroy
  has_many :users, through: :audiences
  has_many :contestants, dependent: :destroy
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"

  validates :title, presence: true

  def to_param
    another_id
  end

  def url
    round_url(self)
  end

  def self.default_url_options
    ActionMailer::Base.default_url_options
  end
end
