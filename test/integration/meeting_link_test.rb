require "test_helper"

# Opening the meeting link: sign in or up if needed, then the join page (name prefilled), then voting
class MeetingLinkTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting) # organized by jimmy; john and gapbun have joined; no passcode
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "1111" }
  end

  test "a new user follows the link, registers, confirms their name, and votes" do
    get round_path(@round)
    assert_redirected_to signin_url
    follow_redirect!
    assert_select "div", "Sign in or create an account to join “meeting”."

    post users_path, params: { user: { username: "newbie", password: "1111" } }
    follow_redirect! # back to the meeting link
    assert_redirected_to new_round_audience_url(@round)
    follow_redirect!
    assert_select "input[name='audience[name]'][value=newbie]"
    assert_select "input[name=passcode]", 0

    assert_difference "@round.audiences.count", 1 do
      post round_audiences_path(@round), params: { audience: { name: "New Member" } }
    end
    assert_redirected_to round_agenda_items_url(@round)
    follow_redirect!
    assert_select "button", "Favor"
    assert_equal "New Member", @round.audiences.find_by!(user: User.find_by!(username: "newbie")).name
  end

  test "a signed-out user follows the link, signs in, and goes to the join page" do
    @round.audiences.find_by!(user: users(:john)).destroy!
    get round_path(@round)
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

  test "an attendee following the link again taps Attend, and isn't joined twice" do
    sign_in "john"
    get round_path(@round)
    assert_redirected_to new_round_audience_url(@round)
    follow_redirect!
    assert_select "p", "You're attending as “Johnny”."
    assert_select "input[name='audience[name]']", 0
    assert_select "input[type=submit][value=Attend]"

    assert_no_difference "@round.audiences.count" do
      post round_audiences_path(@round), params: { audience: { name: "Someone else" } }
    end
    assert_redirected_to round_agenda_items_url(@round)
    assert_equal "Johnny", audiences(:john_at_meeting).reload.name
  end

  test "an attendee of a passcode meeting types the passcode again to get to voting" do
    @round.update!(passcode: "482915")
    sign_in "john"
    get round_path(@round)
    follow_redirect!
    assert_select "input[name=passcode][required]"

    post round_audiences_path(@round), params: { passcode: "000000" }
    assert_response :unprocessable_entity
    assert_select "li", "Passcode is incorrect"
    assert_select "p", "You're attending as “Johnny”."

    post round_audiences_path(@round), params: { passcode: "482915" }
    assert_redirected_to round_agenda_items_url(@round)
  end

  test "the voting page itself doesn't ask again: only the link does" do
    @round.update!(passcode: "482915")
    sign_in "john"
    get round_agenda_items_path(@round)
    assert_response :success
  end

  test "with a passcode, the join page asks for it too, with the name prefilled" do
    @round.update!(passcode: "482915")
    @round.audiences.find_by!(user: users(:john)).destroy!
    sign_in "john"
    assert_no_difference "@round.audiences.count" do
      get round_path(@round)
    end
    assert_redirected_to new_round_audience_url(@round)
    follow_redirect!
    assert_select "input[name=passcode]"
    assert_select "input[name='audience[name]'][value=john]"
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

  test "an unknown meeting link goes home" do
    get round_path("missing")
    assert_redirected_to root_url
  end
end
