class Vote < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :audience
  belongs_to :contestant, counter_cache: true

  enum :choice, { favor: 0, against: 1 }

  validates :contestant_id, uniqueness: { scope: :audience_id }
  validate :audience_in_contestant_round
  validate :user_matches_audience
  validate :voting_open, on: [:create, :update]

  # One callback: registering the same method twice makes the last one win
  after_commit :broadcast_votes_count, unless: :destroyed_by_association

  private

  def audience_in_contestant_round
    if audience && contestant && audience.round_id != contestant.round_id
      errors.add(:audience, "must be in the same round as the contestant")
    end
  end

  def voting_open
    if contestant&.decision_made?
      errors.add(:contestant, "is closed: decision made")
    end
  end

  def user_matches_audience
    if audience && user_id != audience.user_id
      errors.add(:user, "must be the attendee who votes")
    end
  end

  def broadcast_votes_count
    # Broadcast via the contestant: Turbo serializes the broadcasting record into
    # the job, and a destroyed vote can't be loaded back when the job runs
    contestant.broadcast_replace_later_to [contestant.round, :results],
      target: "#{dom_id(contestant)}_votes_count",
      partial: "owner/contestants/votes_count",
      locals: { contestant: contestant }
  end
end
