class Contestant < ApplicationRecord
  belongs_to :round
  has_many :votes, dependent: :destroy

  # A decision vote passes on "favor" votes out of votes cast; nil means tally only
  enum :decision_rule, { majority: 1, two_thirds: 2 }, validate: { allow_nil: true }

  DECISION_RULE_LABELS = { "majority" => "1/2", "two_thirds" => "2/3" }.freeze

  attr_accessor :my_vote

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
