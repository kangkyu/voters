require "test_helper"

class VoteFlowTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:contest)
    @contestant = contestants(:singer)
    post session_path, params: { username: "john", password: "1111" }
  end

  test "audience sees favor and against buttons" do
    get round_contestants_path(@round)
    assert_response :success
    assert_select "button", "Favor"
    assert_select "button", "Against"
  end

  test "audience votes favor, changes to against, then clears" do
    assert_difference "Vote.count", 1 do
      post round_contestant_votes_path(@round, @contestant), params: { choice: "favor" }
    end
    vote = Vote.last
    assert vote.favor?

    assert_no_difference "Vote.count" do
      post round_contestant_votes_path(@round, @contestant), params: { choice: "against" }
    end
    assert vote.reload.against?

    assert_difference "Vote.count", -1 do
      delete round_contestant_vote_path(@round, @contestant, vote)
    end
  end

  test "cannot vote before login" do
    delete session_path

    assert_no_difference "Vote.count" do
      post round_contestant_votes_path(@round, @contestant), params: { choice: "favor" }
    end
    assert_redirected_to signin_path
  end

  test "rejects an unknown choice" do
    assert_no_difference "Vote.count" do
      post round_contestant_votes_path(@round, @contestant), params: { choice: "maybe" }
    end
    assert_response :unprocessable_entity
  end

  test "owner sees favor and against counts in results" do
    @contestant.votes.create!(user: users(:john), choice: :favor)
    @contestant.votes.create!(user: users(:gapbun), choice: :against)
    delete session_path
    post session_path, params: { username: "jimmy", password: "1111" }

    get owner_round_results_path(@round)
    assert_select "turbo-frame##{ActionView::RecordIdentifier.dom_id(@contestant)}_votes_count", /Favor 1\s+Against 1/
  end
end
