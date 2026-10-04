class Contestant < ApplicationRecord
  belongs_to :round
  has_many :votes, dependent: :destroy

  attr_accessor :my_vote

  def favor_count
    votes.favor.count
  end

  def against_count
    votes.against.count
  end

  after_create_commit -> {
    broadcast_append_to "audience_contestants",
      target: "audience_contestant",
      partial: "contestants/contestant",
      locals: { contestant: self }
  }

  after_destroy_commit -> {
    broadcast_remove_to "audience_contestants"
  }
end
