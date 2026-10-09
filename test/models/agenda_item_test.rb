require "test_helper"

class AgendaItemTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  setup do
    @round = rounds(:contest)
  end

  def agenda_item_with_votes(rule, favor:, against:)
    agenda_item = @round.agenda_items.create!(name: "Motion", decision_rule: rule)
    choices = Array.new(favor, "favor") + Array.new(against, "against")
    choices.each_with_index do |choice, i|
      user = User.create!(username: "voter#{agenda_item.id}-#{i}", password: "1111")
      audience = @round.audiences.create!(user: user, name: "Voter #{i}")
      agenda_item.votes.create!(user: user, audience: audience, choice: choice)
    end
    agenda_item
  end

  test "not a decision vote has no decision" do
    assert_nil agenda_item_with_votes(nil, favor: 2, against: 0).decision
  end

  test "decision vote with no votes is pending" do
    assert_equal :pending, agenda_item_with_votes("majority", favor: 0, against: 0).decision
  end

  test "majority needs more than half" do
    assert_equal :passed, agenda_item_with_votes("majority", favor: 2, against: 1).decision
    assert_equal :failed, agenda_item_with_votes("majority", favor: 1, against: 1).decision
  end

  test "two-thirds needs at least 2/3" do
    assert_equal :passed, agenda_item_with_votes("two_thirds", favor: 2, against: 1).decision
    assert_equal :failed, agenda_item_with_votes("two_thirds", favor: 3, against: 2).decision
  end

  test "rejects an unknown decision rule" do
    agenda_item = @round.agenda_items.build(name: "Motion", decision_rule: "unanimous")
    assert_not agenda_item.valid?
  end

  test "new agenda items are broadcast only to their own meeting" do
    other = Round.create!(title: "other", owner: users(:gapbun))
    other.agenda_items.create!(name: "Other item")
    assert_turbo_stream_broadcasts [other, :agenda], count: 1
    assert_no_turbo_stream_broadcasts [@round, :agenda]
  end

  test "loads vote tallies for many agenda_items at once" do
    passed = agenda_item_with_votes("majority", favor: 2, against: 1)
    empty = @round.agenda_items.create!(name: "Empty")
    fresh = AgendaItem.load_vote_tallies(AgendaItem.where(id: [passed.id, empty.id]).order(:id).to_a)
    assert_equal [{ "favor" => 2, "against" => 1 }, { "favor" => 0, "against" => 0 }], fresh.map(&:vote_tally)
  end
end
