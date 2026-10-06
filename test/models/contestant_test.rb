require "test_helper"

class ContestantTest < ActiveSupport::TestCase
  setup do
    @round = rounds(:contest)
  end

  def contestant_with_votes(rule, favor:, against:)
    contestant = @round.contestants.create!(name: "Motion", decision_rule: rule)
    choices = Array.new(favor, "favor") + Array.new(against, "against")
    choices.each_with_index do |choice, i|
      user = User.create!(username: "voter#{contestant.id}-#{i}", password: "1111")
      audience = @round.audiences.create!(user: user, name: "Voter #{i}")
      contestant.votes.create!(user: user, audience: audience, choice: choice)
    end
    contestant
  end

  test "not a decision vote has no decision" do
    assert_nil contestant_with_votes(nil, favor: 2, against: 0).decision
  end

  test "decision vote with no votes is pending" do
    assert_equal :pending, contestant_with_votes("majority", favor: 0, against: 0).decision
  end

  test "majority needs more than half" do
    assert_equal :passed, contestant_with_votes("majority", favor: 2, against: 1).decision
    assert_equal :failed, contestant_with_votes("majority", favor: 1, against: 1).decision
  end

  test "two-thirds needs at least 2/3" do
    assert_equal :passed, contestant_with_votes("two_thirds", favor: 2, against: 1).decision
    assert_equal :failed, contestant_with_votes("two_thirds", favor: 3, against: 2).decision
  end

  test "rejects an unknown decision rule" do
    contestant = @round.contestants.build(name: "Motion", decision_rule: "unanimous")
    assert_not contestant.valid?
  end
end
