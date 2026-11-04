require "test_helper"

class ElectionFlowTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting)
    @election = @round.agenda_items.create!(name: "Chair", kind: "election", candidate_names: "Ann\nBob")
    @ann, @bob = @election.candidates
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "tV7qLm2xRz9pWk4d" }
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

  test "attendee votes for a candidate and cannot change it" do
    sign_in "john"
    assert_difference "Vote.count", 1 do
      post round_agenda_item_votes_path(@round, @election), params: { candidate_id: @ann.id }
    end
    vote = Vote.last
    assert_equal @ann, vote.candidate
    assert_nil vote.choice
    assert_select "#{votes_frame} button[aria-pressed=true]", "Ann"
    assert_select "#{votes_frame} button[disabled]", "Bob"

    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @election), params: { candidate_id: @bob.id }
    end
    assert_response :unprocessable_entity
    assert_equal @ann, vote.reload.candidate
  end

  test "abstains in an election and cannot pick a candidate afterwards" do
    sign_in "john"
    post round_agenda_item_votes_path(@round, @election), params: { choice: "abstain" }
    vote = Vote.last
    assert vote.abstain?
    assert_nil vote.candidate
    assert_select "#{votes_frame} button[aria-pressed=true]", "Abstain"

    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @election), params: { candidate_id: @ann.id }
    end
    assert_response :unprocessable_entity
    vote.reload
    assert vote.abstain?
    assert_nil vote.candidate
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

  test "results show each candidate's votes and who has the most" do
    @election.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), candidate: @bob)
    sign_in "jimmy"
    get owner_round_results_path(@round)
    frame = "turbo-frame##{ActionView::RecordIdentifier.dom_id(@election)}_votes_count"
    assert_select "#{frame} .decision-badge", /Most votes: Bob/
    assert_select "#{frame} .candidate-count", text: /Ann\s+0/
    assert_select "#{frame} .candidate-count", text: /Bob\s+1/
    assert_select "#{frame} .abstain-count", text: /Abstain\s+0/
    assert_select "#{frame} .not-voted-count", text: /Not voted\s+1/
  end

  test "once decided, a candidate wins only with more than half of the votes cast" do
    election = @round.agenda_items.create!(name: "Treasurer", kind: "election", candidate_names: "Cy\nDee\nEd")
    cy, dee, ed = election.candidates
    badge = "##{ActionView::RecordIdentifier.dom_id(election)} .decision-badge"
    outcome = "#minutes_#{ActionView::RecordIdentifier.dom_id(election)} .outcome"
    [cy, cy, dee, ed].each_with_index do |candidate, i|
      user = User.create!(username: "voter#{i}", password: "tV7qLm2xRz9pWk4d")
      election.votes.create!(user: user, audience: @round.audiences.create!(user: user, name: user.username), candidate: candidate)
    end
    sign_in "jimmy"

    get owner_round_results_path(@round)
    assert_select badge, /Most votes: Cy/ # not decided yet

    election.update!(decision_made: true)
    get owner_round_results_path(@round)
    assert_select badge, /Most votes: Cy/ # 2 of 4 is exactly half
    get owner_round_minutes_path(@round)
    assert_select outcome, /Most votes: Cy/

    election.update!(decision_made: false)
    user = User.create!(username: "voter4", password: "tV7qLm2xRz9pWk4d")
    election.votes.create!(user: user, audience: @round.audiences.create!(user: user, name: "voter4"), candidate: cy)
    get owner_round_results_path(@round)
    assert_select badge, /Most votes: Cy/ # a majority, but not decided yet
    get owner_round_minutes_path(@round)
    assert_select outcome, /Most votes: Cy/

    election.update!(decision_made: true)
    get owner_round_results_path(@round)
    assert_select badge, /Cy wins/ # 3 of 5
    get owner_round_minutes_path(@round)
    assert_select outcome, /Elected: Cy/
  end

  test "abstentions don't count toward the votes a candidate needs to win" do
    @election.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), candidate: @bob)
    @election.votes.create!(user: users(:gapbun), audience: audiences(:gapbun_at_meeting), choice: "abstain")
    @election.update!(decision_made: true)
    sign_in "jimmy"
    get owner_round_results_path(@round)
    assert_select "##{ActionView::RecordIdentifier.dom_id(@election)} .decision-badge", /Bob wins/
  end

  test "results list candidates by most votes, level ones in the order entered" do
    frame = "turbo-frame##{ActionView::RecordIdentifier.dom_id(@election)}_votes_count"
    names = -> { css_select("#{frame} .candidate-count span:first-child").map { |name| name.text.strip } }
    sign_in "jimmy"

    get owner_round_results_path(@round)
    assert_equal %w[Ann Bob], names.call

    @election.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), candidate: @bob)
    get owner_round_results_path(@round)
    assert_equal %w[Bob Ann], names.call

    @election.votes.create!(user: users(:gapbun), audience: audiences(:gapbun_at_meeting), candidate: @ann)
    get owner_round_results_path(@round)
    assert_equal %w[Ann Bob], names.call
  end

  test "a new vote reorders the candidates on an open results page" do
    broadcasts = capture_turbo_stream_broadcasts([@round, :results, :en]) do
      perform_enqueued_jobs only: Turbo::Streams::ActionBroadcastJob do
        @election.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), candidate: @bob)
      end
    end
    assert_equal 1, broadcasts.size
    rows = broadcasts.sole.css(".candidate-count").map { |row| row.text.split }
    assert_equal [%w[Bob 1], %w[Ann 0]], rows
  end

  test "checking and unchecking decision made updates the badge on an open results page" do
    @election.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), candidate: @bob)
    badge_after = lambda do |decided|
      broadcasts = capture_turbo_stream_broadcasts([@round, :results, :en]) do
        perform_enqueued_jobs(only: Turbo::Streams::ActionBroadcastJob) { @election.update!(decision_made: decided) }
      end
      broadcasts.sole.css(".decision-badge").text
    end

    assert_match "Bob wins", badge_after.call(true)
    assert_match "Most votes: Bob", badge_after.call(false)
  end

  test "results show a tie" do
    @election.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), candidate: @ann)
    @election.votes.create!(user: users(:gapbun), audience: audiences(:gapbun_at_meeting), candidate: @bob)
    sign_in "jimmy"
    get owner_round_results_path(@round)
    assert_select "##{ActionView::RecordIdentifier.dom_id(@election)} .decision-badge", /Tie · Ann and Bob/
  end
end
