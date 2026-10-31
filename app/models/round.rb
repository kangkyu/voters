class Round < ApplicationRecord
  include Rails.application.routes.url_helpers

  has_many :audiences, dependent: :destroy
  has_many :users, through: :audiences
  has_many :agenda_items, dependent: :destroy
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"

  validates :title, presence: true

  # Chosen once on the new meeting form: whether the organizer votes too, and under what name.
  # When they do, they join as an attendee in the same transaction
  attribute :organizer_votes, :boolean, default: true
  attribute :organizer_name, :string
  validates :organizer_name, presence: true, on: :organize, if: :organizer_votes
  after_create :join_organizer, if: -> { organizer_votes && organizer_name.present? }

  # Ticked on the new meeting form: joining needs the passcode the organizer announces
  attribute :require_passcode, :boolean, default: false
  before_create :generate_passcode, if: :require_passcode

  def self.new_passcode
    SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
  end

  def regenerate_passcode!
    update!(passcode: self.class.new_passcode)
  end

  # True when no passcode is set; spaces typed in the code are ignored
  def passcode_matches?(code)
    passcode.blank? || ActiveSupport::SecurityUtils.secure_compare(passcode, code.to_s.gsub(/\s/, ""))
  end

  def to_param
    another_id
  end

  def url
    round_url(self)
  end

  def self.default_url_options
    ActionMailer::Base.default_url_options
  end

  private

  def join_organizer
    audiences.create!(user: owner, name: organizer_name)
  end

  def generate_passcode
    self.passcode = self.class.new_passcode
  end
end
