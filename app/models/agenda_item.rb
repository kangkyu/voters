class AgendaItem < ApplicationRecord
  belongs_to :round
  has_many :votes, dependent: :destroy
  has_many :candidates, -> { order(:id) }, dependent: :destroy

  # A motion is voted favor / against; an election picks one of its candidates
  enum :kind, { motion: 0, election: 1 }, validate: true

  # A decision vote passes on "favor" votes out of votes cast; nil means tally only
  enum :decision_rule, { majority: 1, two_thirds: 2 }, validate: { allow_nil: true }

  DECISION_RULE_LABELS = { "majority" => "1/2", "two_thirds" => "2/3" }.freeze

  attr_accessor :my_vote
  attr_writer :vote_tally, :candidate_tally, :attendee_count

  # Candidate names typed in by the owner, one per line; turned into candidates on create
  attr_accessor :candidate_names

  validates :decision_rule, absence: { message: "is for motions only" }, if: :election?
  before_validation :build_candidates, on: :create, if: -> { election? && candidates.empty? }
  validate :election_has_candidates, if: :election?

  # Loads favor/against, per-candidate and attendee counts for many agenda_items in two queries
  def self.load_vote_tallies(agenda_items)
    counts = Vote.where(agenda_item_id: agenda_items.map(&:id)).group(:agenda_item_id, :choice, :candidate_id).count
    attendees = Audience.where(round_id: agenda_items.map(&:round_id).uniq).group(:round_id).count
    agenda_items.each do |agenda_item|
      agenda_item.attendee_count = attendees.fetch(agenda_item.round_id, 0)
      mine = counts.select { |(agenda_item_id, _, _), _| agenda_item_id == agenda_item.id }
      agenda_item.vote_tally = Vote.choices.keys.index_with do |choice|
        mine.sum { |(_, vote_choice, _), count| vote_choice == choice ? count : 0 }
      end
      agenda_item.candidate_tally = mine.each_with_object({}) do |((_, _, candidate_id), count), tally|
        tally[candidate_id] = count if candidate_id
      end
    end
  end

  # { "favor" => n, "against" => n }, counted once per instance
  def vote_tally
    @vote_tally ||= Vote.choices.keys.index_with(0).merge(votes.group(:choice).count)
  end

  def decision_rule_label
    DECISION_RULE_LABELS[decision_rule]
  end

  # Share of votes cast needed to pass, as a percentage
  def decision_threshold_percent
    two_thirds? ? 200.0 / 3 : 50.0
  end

  # :passed, :failed, or :pending (no votes yet); nil when not a decision vote
  def decision
    return unless decision_rule

    favor = favor_count
    total = favor + against_count
    return :pending if total.zero?

    passed = two_thirds? ? favor * 3 >= total * 2 : favor * 2 > total
    passed ? :passed : :failed
  end

  def favor_count
    vote_tally["favor"]
  end

  def against_count
    vote_tally["against"]
  end

  def attendee_count
    @attendee_count ||= round.audiences.count
  end

  def votes_cast
    election? ? candidate_tally.values.sum : favor_count + against_count
  end

  # Attendees of the meeting who haven't voted on this item. Shown only:
  # pass / fail and the winner count votes cast
  def not_voted_count
    [attendee_count - votes_cast, 0].max
  end

  # { candidate_id => n }, counted once per instance
  def candidate_tally
    @candidate_tally ||= votes.where.not(candidate_id: nil).group(:candidate_id).count
  end

  def candidate_vote_count(candidate)
    candidate_tally.fetch(candidate.id, 0)
  end

  # Candidates with the most votes: one winner, several on a tie, none before any vote
  def leading_candidates
    top = candidate_tally.values.max
    return [] unless top&.positive?

    candidates.select { |candidate| candidate_vote_count(candidate) == top }
  end

  # Streams are per meeting, so attendees only see their own meeting's agenda
  after_create_commit -> {
    broadcast_append_to [round, :agenda],
      target: "audience_agenda_item",
      partial: "agenda_items/agenda_item",
      locals: { agenda_item: self }
  }

  # Voting pages show each attendee's own vote, so they refresh themselves rather than take shared HTML
  after_update_commit -> {
    broadcast_refresh_later_to [round, :agenda] if saved_change_to_decision_made?
  }

  after_destroy_commit -> {
    broadcast_remove_to [round, :agenda]
  }

  private

  def build_candidates
    candidate_names.to_s.lines.map(&:strip).compact_blank.uniq.each do |name|
      candidates.build(name: name)
    end
  end

  def election_has_candidates
    if candidates.size < 2
      errors.add(:candidate_names, "need at least two names, one per line")
    end
  end
end
