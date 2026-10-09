class AgendaItem < ApplicationRecord
  belongs_to :round
  has_many :votes, dependent: :destroy

  # A decision vote passes on "favor" votes out of votes cast; nil means tally only
  enum :decision_rule, { majority: 1, two_thirds: 2 }, validate: { allow_nil: true }

  DECISION_RULE_LABELS = { "majority" => "1/2", "two_thirds" => "2/3" }.freeze

  attr_accessor :my_vote
  attr_writer :vote_tally

  # Loads favor/against counts for many agenda_items in one query
  def self.load_vote_tallies(agenda_items)
    counts = Vote.where(agenda_item_id: agenda_items.map(&:id)).group(:agenda_item_id, :choice).count
    agenda_items.each do |agenda_item|
      agenda_item.vote_tally = Vote.choices.keys.index_with { |choice| counts[[agenda_item.id, choice]] || 0 }
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
end
