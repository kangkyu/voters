require "test_helper"

class MeetingMinutesTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting)
    @motion = agenda_items(:item)
    @motion.update!(decision_rule: "majority")
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "1111" }
  end

  test "results page links to the minutes in a new tab" do
    sign_in "jimmy"
    get owner_round_results_path(@round)
    assert_select "a[href='#{owner_round_minutes_path(@round)}'][target=_blank]", "Meeting minutes"
  end

  test "minutes show attendees and each item's outcome, without the site header" do
    @motion.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), choice: "favor")
    @motion.votes.create!(user: users(:gapbun), audience: audiences(:gapbun_at_meeting), choice: "abstain")
    election = @round.agenda_items.create!(name: "Chair", kind: "election", candidate_names: "Ann\nBob")
    election.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), candidate: election.candidates.last)
    election.update!(decision_made: true)

    sign_in "jimmy"
    get owner_round_minutes_path(@round)
    assert_response :success
    assert_select "header nav", 0
    assert_select "h1", "“meeting”"
    assert_select "h2", /2 attendees/
    assert_select ".attendees", "Johnny and Gap"

    motion = "#minutes_#{ActionView::RecordIdentifier.dom_id(@motion)}"
    assert_select "#{motion} .outcome", "Passed"
    assert_select "#{motion} .tally", /Favor 1 · Against 0 · Abstain 1 · Not voted 0/
    assert_select motion, /Voting was still open/

    chair = "#minutes_#{ActionView::RecordIdentifier.dom_id(election)}"
    assert_select "#{chair} .outcome", /Elected: Bob/
    assert_select chair, { text: /Voting was still open/, count: 0 }
  end

  test "only the owner sees the minutes" do
    sign_in "john"
    get owner_round_minutes_path(@round)
    assert_redirected_to user_url(users(:john).another_id)
  end
end
