require "test_helper"

class ElectionTest < ActiveSupport::TestCase
  setup do
    @round = rounds(:contest)
  end

  def election(names = "Ann\nBob\nCy")
    @round.agenda_items.create!(name: "Chair", kind: "election", candidate_names: names)
  end

  # Casts one vote per name given, each from a new attendee
  def vote_for(agenda_item, *names)
    names.each_with_index do |name, i|
      user = User.create!(username: "voter#{agenda_item.id}-#{i}", password: "1111")
      audience = @round.audiences.create!(user: user, name: "Voter #{i}")
      agenda_item.votes.create!(user: user, audience: audience, candidate: agenda_item.candidates.find_by!(name: name))
    end
    agenda_item
  end

  test "creates candidates from the typed names, one per line" do
    assert_equal ["Ann", "Bob"], election("  Ann \n\nBob\nAnn\n").candidates.map(&:name)
  end

  test "needs at least two candidates" do
    agenda_item = @round.agenda_items.build(name: "Chair", kind: "election", candidate_names: "Ann")
    assert_not agenda_item.valid?
    assert_includes agenda_item.errors[:candidate_names], "need at least two names, one per line"
  end

  test "has no decision rule" do
    agenda_item = @round.agenda_items.build(name: "Chair", kind: "election", candidate_names: "Ann\nBob", decision_rule: "majority")
    assert_not agenda_item.valid?
    assert_includes agenda_item.errors[:decision_rule], "is for motions only"
  end

  test "a motion gets no candidates" do
    assert_empty @round.agenda_items.create!(name: "Budget", candidate_names: "Ann\nBob").candidates
  end

  test "rejects an unknown kind" do
    assert_not @round.agenda_items.build(name: "Chair", kind: "poll").valid?
  end

  test "no leader before any vote" do
    assert_empty election.leading_candidates
  end

  test "most votes wins" do
    assert_equal ["Bob"], vote_for(election, "Bob", "Ann", "Bob").leading_candidates.map(&:name)
  end

  test "a tie has several leaders" do
    assert_equal ["Ann", "Bob"], vote_for(election, "Ann", "Bob").leading_candidates.map(&:name)
  end

  test "loads candidate tallies for many agenda items at once" do
    voted = vote_for(election, "Ann", "Ann", "Cy")
    empty = election
    fresh = AgendaItem.load_vote_tallies(AgendaItem.where(id: [voted.id, empty.id]).order(:id).to_a)
    ann, _bob, cy = voted.candidates
    assert_equal [{ ann.id => 2, cy.id => 1 }, {}], fresh.map(&:candidate_tally)
    assert_equal [{ "favor" => 0, "against" => 0 }] * 2, fresh.map(&:vote_tally)
  end

  test "an election vote must name one of its own candidates" do
    agenda_item = election
    other = election("Dee\nEd")
    vote = agenda_item.votes.build(user: users(:john), audience: audiences(:john_at_contest), candidate: other.candidates.first)
    assert_not vote.valid?
    assert_includes vote.errors[:candidate], "must be one of this election's candidates"

    vote.candidate = nil
    assert_not vote.valid?
  end

  test "an election vote has no favor / against choice" do
    agenda_item = election
    vote = agenda_item.votes.build(user: users(:john), audience: audiences(:john_at_contest), candidate: agenda_item.candidates.first, choice: "favor")
    assert_not vote.valid?
    assert_includes vote.errors[:choice], "must be blank in an election"
  end

  test "a motion vote needs a choice and no candidate" do
    vote = agenda_items(:singer).votes.build(user: users(:john), audience: audiences(:john_at_contest))
    assert_not vote.valid?
    assert_includes vote.errors[:choice], "can't be blank"

    vote.choice = "favor"
    vote.candidate = election.candidates.first
    assert_not vote.valid?
    assert_includes vote.errors[:candidate], "must be blank on a motion"
  end
end
