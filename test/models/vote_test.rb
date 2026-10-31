require "test_helper"

class VoteTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Turbo::Broadcastable::TestHelper

  setup do
    @agenda_item = agenda_items(:item)
  end

  def cast_vote
    @agenda_item.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), choice: "favor")
  end

  # One tally job per language
  test "broadcasts the tally when a vote is cast" do
    assert_enqueued_jobs 2, only: Turbo::Streams::ActionBroadcastJob do
      cast_vote
    end
  end

  test "a cast vote can't be changed" do
    vote = cast_vote
    assert_not vote.update(choice: "against")
    assert_includes vote.errors[:base], "A vote can't be changed once cast"
    assert vote.reload.favor?
  end

  test "an election vote can't switch candidates" do
    election = agenda_items(:item).round.agenda_items.create!(name: "Chair", kind: "election", candidate_names: "Ann\nBob")
    ann, bob = election.candidates.order(:id).to_a
    vote = election.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), candidate: ann)
    assert_not vote.update(candidate: bob)
  end

  test "broadcasts the tally when a vote is withdrawn" do
    vote = cast_vote
    assert_enqueued_jobs 2, only: Turbo::Streams::ActionBroadcastJob do
      vote.destroy!
    end
  end

  test "the withdrawn vote broadcast still runs after the vote is gone" do
    vote = cast_vote
    perform_enqueued_jobs only: Turbo::Streams::ActionBroadcastJob do
      vote.destroy!
    end
    assert_turbo_stream_broadcasts [@agenda_item.round, :results, :en], count: 1
  end

  test "tally updates go only to the vote's own meeting" do
    other = Round.create!(title: "other", owner: users(:gapbun))
    perform_enqueued_jobs only: Turbo::Streams::ActionBroadcastJob do
      cast_vote
    end
    assert_turbo_stream_broadcasts [@agenda_item.round, :results, :en], count: 1
    assert_no_turbo_stream_broadcasts [other, :results, :en]
  end

  test "each language's results stream gets the tally rendered in that language" do
    perform_enqueued_jobs only: Turbo::Streams::ActionBroadcastJob do
      cast_vote
    end
    assert_match "Favor", capture_turbo_stream_broadcasts([@agenda_item.round, :results, :en]).sole.to_html
    assert_match "찬성", capture_turbo_stream_broadcasts([@agenda_item.round, :results, :ko]).sole.to_html
  end

  test "rejects a vote whose user is not the attendee" do
    vote = @agenda_item.votes.build(user: users(:gapbun), audience: audiences(:john_at_meeting))
    assert_not vote.valid?
    assert_includes vote.errors[:user], "must be the attendee who votes"
  end
end
