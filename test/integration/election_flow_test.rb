require "test_helper"

class ElectionFlowTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:contest)
    @election = @round.agenda_items.create!(name: "Chair", kind: "election", candidate_names: "Ann\nBob")
    @ann, @bob = @election.candidates
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "1111" }
  end

  def votes_frame = "turbo-frame##{ActionView::RecordIdentifier.dom_id(@election)}_votes"

  test "owner adds an election with its candidates" do
    sign_in "jimmy"
    assert_difference "AgendaItem.count" => 1, "Candidate.count" => 3 do
      post owner_round_agenda_items_path(@round), params: { agenda_item: { name: "Treasurer", kind: "election", candidate_names: "Cy\nDee\nEd" } }, as: :turbo_stream
    end
    assert AgendaItem.last.election?
    assert_select "turbo-stream[action=append][target=admin_agenda_items]", text: /Election · 3 candidates/
    assert_select "turbo-stream[action=append][target=admin_agenda_items] .candidates", "Cy, Dee, and Ed"
  end

  test "owner sees why an election was not added" do
    sign_in "jimmy"
    assert_no_difference "AgendaItem.count" do
      post owner_round_agenda_items_path(@round), params: { agenda_item: { name: "Treasurer", kind: "election", candidate_names: "Cy" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
    assert_select "turbo-stream[action=replace][target=new_agenda_item_form]", text: /Candidates need at least two names/
    assert_select "turbo-stream[action=replace][target=new_agenda_item_form] textarea[name='agenda_item[candidate_names]']", "Cy"
  end

  test "attendee sees a button per candidate" do
    sign_in "john"
    get round_agenda_items_path(@round)
    assert_select "#{votes_frame} button", "Ann"
    assert_select "#{votes_frame} button", "Bob"
    assert_select "#{votes_frame} button", text: "Favor", count: 0
  end

  test "attendee votes, changes the vote, then withdraws it" do
    sign_in "john"
    assert_difference "Vote.count", 1 do
      post round_agenda_item_votes_path(@round, @election), params: { candidate_id: @ann.id }
    end
    vote = Vote.last
    assert_equal @ann, vote.candidate
    assert_nil vote.choice

    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @election), params: { candidate_id: @bob.id }
    end
    assert_equal @bob, vote.reload.candidate
    # Bob is now my vote, so clicking him withdraws it
    assert_select "#{votes_frame} form[action='#{round_agenda_item_vote_path(@round, @election, vote)}'] button", "Bob"

    assert_difference "Vote.count", -1 do
      delete round_agenda_item_vote_path(@round, @election, vote)
    end
  end

  test "rejects a candidate from another election" do
    other = @round.agenda_items.create!(name: "Treasurer", kind: "election", candidate_names: "Cy\nDee")
    sign_in "john"
    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @election), params: { candidate_id: other.candidates.first.id }
    end
    assert_response :unprocessable_entity
  end

  test "rejects a favor / against vote in an election" do
    sign_in "john"
    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @election), params: { choice: "favor" }
    end
    assert_response :unprocessable_entity
  end

  test "no vote changes once the decision is made" do
    @election.update!(decision_made: true)
    sign_in "john"
    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @election), params: { candidate_id: @ann.id }
    end
    assert_response :unprocessable_entity
    assert_select "#{votes_frame} button[disabled]", "Ann"
  end

  test "results show each candidate's votes and the winner" do
    @election.votes.create!(user: users(:john), audience: audiences(:john_at_contest), candidate: @bob)
    sign_in "jimmy"
    get owner_round_results_path(@round)
    frame = "turbo-frame##{ActionView::RecordIdentifier.dom_id(@election)}_votes_count"
    assert_select "#{frame} .decision-badge", /Bob wins/
    assert_select "#{frame} .candidate-count", text: /Ann\s+0/
    assert_select "#{frame} .candidate-count", text: /Bob\s+1/
    assert_select "#{frame} .not-voted-count", text: /Not voted\s+1/
  end

  test "results show a tie" do
    @election.votes.create!(user: users(:john), audience: audiences(:john_at_contest), candidate: @ann)
    @election.votes.create!(user: users(:gapbun), audience: audiences(:gapbun_at_contest), candidate: @bob)
    sign_in "jimmy"
    get owner_round_results_path(@round)
    assert_select "##{ActionView::RecordIdentifier.dom_id(@election)} .decision-badge", /Tie · Ann and Bob/
  end
end
