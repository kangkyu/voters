class Vote < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :audience
  belongs_to :agenda_item, counter_cache: true

  enum :choice, { favor: 0, against: 1 }

  validates :agenda_item_id, uniqueness: { scope: :audience_id }
  validate :audience_in_agenda_item_round
  validate :user_matches_audience
  validate :voting_open, on: [:create, :update]

  # One callback: registering the same method twice makes the last one win
  after_commit :broadcast_votes_count, unless: :destroyed_by_association

  private

  def audience_in_agenda_item_round
    if audience && agenda_item && audience.round_id != agenda_item.round_id
      errors.add(:audience, "must be in the same round as the agenda_item")
    end
  end

  def voting_open
    if agenda_item&.decision_made?
      errors.add(:agenda_item, "is closed: decision made")
    end
  end

  def user_matches_audience
    if audience && user_id != audience.user_id
      errors.add(:user, "must be the attendee who votes")
    end
  end

  def broadcast_votes_count
    # Broadcast via the agenda_item: Turbo serializes the broadcasting record into
    # the job, and a destroyed vote can't be loaded back when the job runs
    agenda_item.broadcast_replace_later_to [agenda_item.round, :results],
      target: "#{dom_id(agenda_item)}_votes_count",
      partial: "owner/agenda_items/votes_count",
      locals: { agenda_item: agenda_item }
  end
end
