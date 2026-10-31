require "test_helper"

# The organizer chooses once, when starting the meeting, whether they vote in it too
class OrganizerAttendanceTest < ActionDispatch::IntegrationTest
  def sign_in(username)
    post session_path, params: { username: username, password: "1111" }
  end

  def start_meeting(**round)
    post rounds_path, params: { round: { title: "Board" }.merge(round) }
  end

  test "the new meeting form has voting ticked, with the name prefilled with the username" do
    sign_in "jimmy"
    get new_round_path
    assert_select "input[type=checkbox][name='round[organizer_votes]'][checked]"
    assert_select "label", /I'll vote in this meeting/
    assert_select "input[name='round[organizer_name]'][required][value=jimmy]"
  end

  test "an organizer who votes joins as an attendee under the name they gave" do
    sign_in "jimmy"
    start_meeting(organizer_votes: "1", organizer_name: "Jimmy (Chair)")
    round = Round.last
    attendance = round.audiences.sole
    assert_equal [users(:jimmy), "Jimmy (Chair)"], [attendance.user, attendance.name]

    follow_redirect!
    assert_select "a[href='#{round_agenda_items_path(round)}']", "Vote"
  end

  test "an organizer who only runs the meeting isn't an attendee and isn't asked a name" do
    sign_in "jimmy"
    assert_difference "Round.count", 1 do
      start_meeting(organizer_votes: "0")
    end
    round = Round.last
    assert_empty round.audiences

    follow_redirect!
    assert_select "a[href='#{round_agenda_items_path(round)}']", 0
  end

  test "voting needs a name" do
    sign_in "jimmy"
    assert_no_difference ["Round.count", "Audience.count"] do
      start_meeting(organizer_votes: "1", organizer_name: " ")
    end
    assert_response :unprocessable_entity
    assert_select "form li", "Your name in this meeting can't be blank"
    # The form comes back as it was sent
    assert_select "input[type=checkbox][name='round[organizer_votes]'][checked]"
  end

  test "the form comes back with voting unticked and the name hidden when that was sent" do
    sign_in "jimmy"
    start_meeting(title: "", organizer_votes: "0")
    assert_response :unprocessable_entity
    assert_select "form li", "Title can't be blank"
    assert_select "input[type=checkbox][name='round[organizer_votes]'][checked]", 0
    assert_select "div[hidden] input[name='round[organizer_name]'][disabled]"
  end

  test "the choice reads in Korean too" do
    users(:jimmy).update!(locale: "ko")
    sign_in "jimmy"
    get new_round_path
    assert_select "label", /이 회의에서 나도 투표하기/
    assert_select "label", "이 회의에서 쓸 내 이름"
  end

  test "an organizer who votes stays on the attendee list: no Remove for them" do
    sign_in "jimmy"
    start_meeting(organizer_votes: "1", organizer_name: "Chair")
    round = Round.last
    round.audiences.create!(user: users(:john), name: "Johnny")

    get owner_round_audiences_path(round)
    assert_select "tr", /Chair/ do |rows|
      assert_select rows.first, "button", 0
      assert_select rows.first, "span", "Organizer"
    end
    assert_select "tr", /Johnny/ do |rows|
      assert_select rows.first, "button", "Remove"
    end

    organizer = round.audiences.find_by!(user: users(:jimmy))
    assert_no_difference "round.audiences.count" do
      delete owner_round_audience_path(round, organizer)
    end
    assert_redirected_to owner_round_audiences_url(round)
    assert_equal "The organizer chose to vote when starting the meeting, so they stay on the attendee list.", flash[:alert]
  end
end
