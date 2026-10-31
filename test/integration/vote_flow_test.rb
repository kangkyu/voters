require "test_helper"

class VoteFlowTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting)
    @agenda_item = agenda_items(:item)
    post session_path, params: { username: "john", password: "1111" }
  end

  test "audience sees favor and against buttons" do
    get round_agenda_items_path(@round)
    assert_response :success
    assert_select "button", "Favor"
    assert_select "button", "Against"
    assert_select "button", "Abstain"
  end

  test "abstains, and the vote is final" do
    votes_frame = "turbo-frame##{ActionView::RecordIdentifier.dom_id(@agenda_item)}_votes"
    assert_difference "Vote.count", 1 do
      post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "abstain" }
    end
    assert Vote.last.abstain?
    assert_select "#{votes_frame} button[aria-pressed=true]", "Abstain"

    post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "favor" }
    assert_response :unprocessable_entity
    assert Vote.last.abstain?
    assert_select "#{votes_frame} button[aria-pressed=true]", "Abstain"
  end

  test "before voting every option can be cast; after, my vote stays and the rest are locked" do
    votes_frame = "turbo-frame##{ActionView::RecordIdentifier.dom_id(@agenda_item)}_votes"
    get round_agenda_items_path(@round)
    assert_select "#{votes_frame} form", 3
    assert_select "#{votes_frame} form[data-turbo-confirm]", 3
    assert_select "#{votes_frame} button", text: "No vote", count: 0

    post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "favor" }
    assert_select votes_frame do
      assert_select "span", "Vote cast"
      assert_select "button[aria-pressed=true]", "Favor"
      assert_select "button[disabled]", 2
      assert_select "form", 0
    end

    get round_agenda_items_path(@round)
    assert_select "#{votes_frame} button[aria-pressed=true]", "Favor"
    assert_select "#{votes_frame} form", 0
  end

  test "audience votes favor and cannot change or withdraw it" do
    assert_difference "Vote.count", 1 do
      post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "favor" }
    end
    vote = Vote.last
    assert vote.favor?
    assert_equal audiences(:john_at_meeting), vote.audience

    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "against" }
    end
    assert_response :unprocessable_entity
    assert vote.reload.favor?

    delete "/rounds/#{@round.id}/agenda_items/#{@agenda_item.id}/votes/#{vote.id}"
    assert_response :not_found
    assert Vote.exists?(vote.id)
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

  test "owner sees favor, against and not voted counts in results" do
    @agenda_item.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), choice: :favor)
    @agenda_item.votes.create!(user: users(:gapbun), audience: audiences(:gapbun_at_meeting), choice: :against)
    @round.audiences.create!(user: users(:jimmy), name: "Jim")
    delete session_path
    post session_path, params: { username: "jimmy", password: "1111" }

    get owner_round_results_path(@round)
    assert_select "turbo-frame##{ActionView::RecordIdentifier.dom_id(@agenda_item)}_votes_count", /Favor 1\s+Against 1\s+Abstain 0\s+Not voted 1/
  end
end
