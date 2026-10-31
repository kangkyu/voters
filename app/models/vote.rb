class Vote < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :audience
  belongs_to :agenda_item, counter_cache: true
  belongs_to :candidate, optional: true

  # Abstain is a recorded vote that counts as attending, but not for or against
  enum :choice, { favor: 0, against: 1, abstain: 2 }

  validates :agenda_item_id, uniqueness: { scope: :audience_id }
  validate :audience_in_agenda_item_round
  validate :user_matches_audience
  validate :matches_agenda_item_kind
  validate :voting_open, on: [:create, :update]
  validate :cast_once, on: :update

  # One callback: registering the same method twice makes the last one win
  after_commit :broadcast_votes_count, unless: :destroyed_by_association

  private

  def audience_in_agenda_item_round
    if audience && agenda_item && audience.round_id != agenda_item.round_id
      errors.add(:audience, :other_round)
    end
  end

  def voting_open
    if agenda_item&.decision_made?
      errors.add(:agenda_item, :closed)
    end
  end

  # Like a ballot in the box: once cast, the choice can't be changed
  def cast_once
    if will_save_change_to_choice? || will_save_change_to_candidate_id?
      errors.add(:base, :already_cast)
    end
  end

  # A motion vote is favor / against / abstain; an election vote names one of that election's candidates, or abstains
  def matches_agenda_item_kind
    return unless agenda_item

    if agenda_item.election? && abstain?
      errors.add(:candidate, :blank_when_abstaining) if candidate_id
    elsif agenda_item.election?
      errors.add(:candidate, :not_in_election) unless candidate&.agenda_item_id == agenda_item_id
      errors.add(:choice, :not_in_election) if choice
    else
      errors.add(:choice, :blank) unless choice
      errors.add(:candidate, :not_on_motion) if candidate_id
    end
  end

  def user_matches_audience
    if audience && user_id != audience.user_id
      errors.add(:user, :not_attendee)
    end
  end

  def broadcast_votes_count
    # Broadcast via the agenda_item: Turbo serializes the broadcasting record into
    # the job, and a destroyed vote can't be loaded back when the job runs.
    # The job renders without a request, so each language gets its own render and stream
    I18n.available_locales.each do |locale|
      agenda_item.broadcast_replace_later_to [agenda_item.round, :results, locale],
        target: "#{dom_id(agenda_item)}_votes_count",
        partial: "owner/agenda_items/votes_count",
        locals: { agenda_item: agenda_item, locale: locale.to_s }
    end
  end
end
