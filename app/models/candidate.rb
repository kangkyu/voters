class Candidate < ApplicationRecord
  belongs_to :agenda_item
  has_many :votes, dependent: :destroy

  validates :name, presence: true
end
