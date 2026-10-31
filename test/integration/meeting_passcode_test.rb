require "test_helper"

class MeetingPasscodeTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting)
    @round.update!(passcode: "482915")
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "1111" }
  end

  def join(passcode: nil)
    post round_audiences_path(@round), params: { audience: { name: "Jim" }, passcode: passcode }.compact
  end

  test "the new meeting form leaves the passcode off unless checked" do
    sign_in "jimmy"
    get new_round_path
    assert_select "input[type=checkbox][name='round[require_passcode]']"
    assert_select "input[type=checkbox][name='round[require_passcode]'][checked]", 0
  end

  test "a new meeting can require a passcode" do
    sign_in "jimmy"
    post rounds_path, params: { round: { title: "AGM", require_passcode: "1" } }
    assert_match(/\A\d{6}\z/, Round.last.passcode)

    post rounds_path, params: { round: { title: "Picnic", require_passcode: "0" } }
    assert_nil Round.last.passcode
  end

  test "joining asks for the passcode and accepts the right one" do
    sign_in "gapbun"
    @round.audiences.destroy_all

    get new_round_audience_path(@round)
    assert_select "input[name=passcode]"

    assert_no_difference "Audience.count" do
      join(passcode: "111111")
    end
    assert_response :unprocessable_entity
    assert_select "li", "Passcode is incorrect"

    assert_difference "Audience.count", 1 do
      join(passcode: "482 915")
    end
    assert_redirected_to round_agenda_items_url(@round)
  end

  test "joining without a passcode set needs none" do
    @round.update!(passcode: nil)
    sign_in "gapbun"
    @round.audiences.destroy_all

    get new_round_audience_path(@round)
    assert_select "input[name=passcode]", 0
    assert_difference("Audience.count", 1) { join }
  end

  test "the organizer joins their own meeting without the passcode" do
    sign_in "jimmy"
    get new_round_audience_path(@round)
    assert_select "input[name=passcode]", 0
    assert_difference("Audience.count", 1) { join }
  end

  test "organizer sees the passcode, makes a new one, and turns it off" do
    sign_in "jimmy"
    get round_path(@round)
    assert_select "#passcode .passcode", "482915"

    post owner_round_passcode_path(@round)
    assert_not_equal "482915", @round.reload.passcode
    assert_redirected_to round_url(@round, anchor: "passcode")

    delete owner_round_passcode_path(@round)
    assert_nil @round.reload.passcode
    follow_redirect!
    assert_select "#passcode button", "Require a passcode"
  end

  test "attendees don't see the passcode or change it" do
    sign_in "john"
    get round_path(@round)
    assert_select "#passcode", 0

    delete owner_round_passcode_path(@round)
    assert_equal "482915", @round.reload.passcode
  end
end
