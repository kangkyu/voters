require "test_helper"

class VoteFlowTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:contest)
    @agenda_item = agenda_items(:singer)
    post session_path, params: { username: "john", password: "1111" }
  end

  test "audience sees favor and against buttons" do
    get round_agenda_items_path(@round)
    assert_response :success
    assert_select "button", "Favor"
    assert_select "button", "Against"
  end

  test "audience votes favor, changes to against, then clears" do
    assert_difference "Vote.count", 1 do
      post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "favor" }
    end
    vote = Vote.last
    assert vote.favor?
    assert_equal audiences(:john_at_contest), vote.audience

    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "against" }
    end
    assert vote.reload.against?

    assert_difference "Vote.count", -1 do
      delete round_agenda_item_vote_path(@round, @agenda_item, vote)
    end
  end

  test "cannot vote before login" do
    delete session_path

    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "favor" }
    end
    assert_redirected_to signin_path
  end

  test "member who has not joined the meeting cannot vote" do
    delete session_path
    post session_path, params: { username: "jimmy", password: "1111" }

    get round_agenda_items_path(@round)
    assert_redirected_to new_round_audience_path(@round)

    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "favor" }
    end
    assert_redirected_to new_round_audience_path(@round)
  end

  test "rejects an unknown choice" do
    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "maybe" }
    end
    assert_response :unprocessable_entity
  end

  test "owner sees favor and against counts in results" do
    @agenda_item.votes.create!(user: users(:john), audience: audiences(:john_at_contest), choice: :favor)
    @agenda_item.votes.create!(user: users(:gapbun), audience: audiences(:gapbun_at_contest), choice: :against)
    delete session_path
    post session_path, params: { username: "jimmy", password: "1111" }

    get owner_round_results_path(@round)
    assert_select "turbo-frame##{ActionView::RecordIdentifier.dom_id(@agenda_item)}_votes_count", /Favor 1\s+Against 1/
  end
end
