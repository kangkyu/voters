require "test_helper"

class VoteTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionCable::TestHelper

  setup do
    @contestant = contestants(:singer)
  end

  def cast_vote
    @contestant.votes.create!(user: users(:john), audience: audiences(:john_at_contest), choice: "favor")
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
    assert_broadcasts "activity", 1 do
      perform_enqueued_jobs only: Turbo::Streams::ActionBroadcastJob do
        vote.destroy!
      end
    end
  end
end
