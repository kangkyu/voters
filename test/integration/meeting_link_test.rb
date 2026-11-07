require "test_helper"

# Opening the meeting link: sign in or up if needed, then the join page, then voting
class MeetingLinkTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting) # organized by jimmy; john and gapbun have joined; no passcode
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "tV7qLm2xRz9pWk4d" }
  end

  test "a new user follows the link, registers, attends under their username, and votes" do
    get round_path(@round)
    assert_redirected_to register_url
    follow_redirect!
    assert_select "div", "Create an account or sign in to join “meeting”."
    assert_select "h2", "Been here before?"
    assert_select "a[href='#{signin_path}']", "Sign in"

    post users_path, params: { user: { username: "newbie", password: "tV7qLm2xRz9pWk4d" } }
    follow_redirect! # back to the meeting link
    assert_redirected_to new_round_audience_url(@round)
    follow_redirect!
    assert_select "p", "You'll attend as “newbie”."
    assert_select "input[name=passcode]", 0

    assert_difference "@round.audiences.count", 1 do
      post round_audiences_path(@round)
    end
    assert_redirected_to round_agenda_items_url(@round)
    follow_redirect!
    assert_select "button", "Favor"
    assert_equal "newbie", @round.audiences.find_by!(user: User.find_by!(username: "newbie")).name
  end

  test "a signed-out user follows the link, goes from sign-up to sign-in, and gets to the join page" do
    @round.audiences.find_by!(user: users(:john)).destroy!
    get round_path(@round)
    assert_redirected_to register_url
    get signin_path
    sign_in "john"
    follow_redirect!
    assert_redirected_to new_round_audience_url(@round)
  end

  test "following the link doesn't join anyone by itself, with or without a passcode" do
    @round.audiences.find_by!(user: users(:john)).destroy!
    sign_in "john"
    assert_no_difference "@round.audiences.count" do
      get round_path(@round)
      @round.update!(passcode: "482915")
      get round_path(@round)
    end
    assert_redirected_to new_round_audience_url(@round)
  end

  test "an attendee following the link goes straight to voting, without tapping Attend" do
    sign_in "john"
    assert_no_difference "@round.audiences.count" do
      get round_path(@round)
    end
    assert_redirected_to round_agenda_items_url(@round)
    assert_equal "Johnny", audiences(:john_at_meeting).reload.name
  end

  test "an attendee of a passcode meeting isn't asked for the passcode again" do
    @round.update!(passcode: "482915")
    sign_in "john"
    get round_path(@round)
    assert_redirected_to round_agenda_items_url(@round)
  end

  test "a signed-out attendee follows the link, signs in, and goes straight to voting" do
    get round_path(@round)
    sign_in "john"
    follow_redirect!
    assert_redirected_to round_agenda_items_url(@round)
  end

  test "an attendee on the join page, or submitting it again, goes to voting and isn't joined twice" do
    @round.update!(passcode: "482915")
    sign_in "john"
    get new_round_audience_path(@round)
    assert_redirected_to round_agenda_items_url(@round)

    assert_no_difference "@round.audiences.count" do
      post round_audiences_path(@round)
    end
    assert_redirected_to round_agenda_items_url(@round)
  end

  test "an attendee who was removed has to attend again" do
    @round.update!(passcode: "482915")
    audiences(:john_at_meeting).destroy!
    sign_in "john"
    get round_path(@round)
    assert_redirected_to new_round_audience_url(@round)
    follow_redirect!
    assert_select "input[name=passcode][required]"
  end

  test "with a passcode, the right one joins a new attendee under their username" do
    @round.update!(passcode: "482915")
    @round.audiences.find_by!(user: users(:john)).destroy!
    sign_in "john"
    assert_no_difference "@round.audiences.count" do
      get round_path(@round)
    end
    assert_redirected_to new_round_audience_url(@round)
    follow_redirect!
    assert_select "input[name=passcode]"
    assert_select "p", "You'll attend as “john”."

    assert_difference "@round.audiences.count", 1 do
      post round_audiences_path(@round), params: { passcode: "482915" }
    end
    assert_redirected_to round_agenda_items_url(@round)
    assert_equal "john", @round.audiences.find_by!(user: users(:john)).name
  end

  test "the organizer gets the meeting page and isn't joined" do
    sign_in "jimmy"
    assert_no_difference "@round.audiences.count" do
      get round_path(@round)
    end
    assert_response :success
    assert_select "h2", "Run the meeting"
  end

  test "the voting page title links to the meeting page only for the organizer" do
    sign_in "john"
    get round_agenda_items_path(@round)
    assert_select "h1 a", 0

    delete session_path
    @round.audiences.create!(user: users(:jimmy), name: "Chair")
    sign_in "jimmy"
    get round_agenda_items_path(@round)
    assert_select "h1 a[href='#{round_path(@round)}']"
  end

  test "the Vote link in the nav is only for an organizer who votes, not a regular attendee" do
    sign_in "john"
    get round_agenda_items_path(@round)
    assert_select "nav a[href='#{round_agenda_items_path(@round)}']", 0

    delete session_path
    sign_in "jimmy"
    get owner_round_results_path(@round)
    assert_select "nav a[href='#{round_agenda_items_path(@round)}']", 0

    @round.audiences.create!(user: users(:jimmy), name: "Chair")
    get owner_round_results_path(@round)
    assert_select "nav a[href='#{round_agenda_items_path(@round)}']", "Vote"
  end

  test "an unknown meeting link goes home" do
    get round_path("missing")
    assert_redirected_to root_url
  end
end
