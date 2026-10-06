class Vote < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :audience
  belongs_to :contestant, counter_cache: true

  enum :choice, { favor: 0, against: 1 }

  validates :contestant_id, uniqueness: { scope: :audience_id }
  validate :audience_in_contestant_round

  # One callback: registering the same method twice makes the last one win
  after_commit :broadcast_votes_count, unless: :destroyed_by_association

  private

  def audience_in_contestant_round
    if audience && contestant && audience.round_id != contestant.round_id
      errors.add(:audience, "must be in the same round as the contestant")
    end
  end

  def broadcast_votes_count
    # Broadcast via the contestant: Turbo serializes the broadcasting record into
    # the job, and a destroyed vote can't be loaded back when the job runs
    contestant.broadcast_replace_later_to "activity",
      target: "#{dom_id(contestant)}_votes_count",
      partial: "owner/contestants/votes_count",
      locals: { contestant: contestant }
  end
end
