require "test_helper"

class VoteTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Turbo::Broadcastable::TestHelper

  setup do
    @agenda_item = agenda_items(:singer)
  end

  def cast_vote
    @agenda_item.votes.create!(user: users(:john), audience: audiences(:john_at_contest), choice: "favor")
  end

  test "broadcasts the tally when a vote is cast" do
    assert_enqueued_jobs 1, only: Turbo::Streams::ActionBroadcastJob do
      cast_vote
    end
  end

  test "broadcasts the tally when a vote is changed" do
    vote = cast_vote
    assert_enqueued_jobs 1, only: Turbo::Streams::ActionBroadcastJob do
      vote.update!(choice: "against")
    end
  end

  test "broadcasts the tally when a vote is withdrawn" do
    vote = cast_vote
    assert_enqueued_jobs 1, only: Turbo::Streams::ActionBroadcastJob do
      vote.destroy!
    end
  end

  test "the withdrawn vote broadcast still runs after the vote is gone" do
    vote = cast_vote
    perform_enqueued_jobs only: Turbo::Streams::ActionBroadcastJob do
      vote.destroy!
    end
    assert_turbo_stream_broadcasts [@agenda_item.round, :results], count: 1
  end

  test "tally updates go only to the vote's own meeting" do
    other = Round.create!(title: "other", owner: users(:gapbun))
    perform_enqueued_jobs only: Turbo::Streams::ActionBroadcastJob do
      cast_vote
    end
    assert_turbo_stream_broadcasts [@agenda_item.round, :results], count: 1
    assert_no_turbo_stream_broadcasts [other, :results]
  end

  test "rejects a vote whose user is not the attendee" do
    vote = @agenda_item.votes.build(user: users(:gapbun), audience: audiences(:john_at_contest))
    assert_not vote.valid?
    assert_includes vote.errors[:user], "must be the attendee who votes"
  end
end
