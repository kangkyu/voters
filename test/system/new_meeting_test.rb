require "application_system_test_case"

class NewMeetingTest < ApplicationSystemTestCase
  setup do
    visit signin_path
    fill_in "username", with: "jimmy"
    fill_in "password", with: "1111"
    click_button "Sign In"
    assert_no_text "Not logged in"
    visit new_round_path
  end

  test "unticking voting hides the name, and the meeting starts without it" do
    fill_in "Title", with: "Board"
    assert_field "Your name in this meeting", with: "jimmy"

    uncheck "I'll vote in this meeting"
    assert_no_field "Your name in this meeting"
    check "I'll vote in this meeting"
    assert_field "Your name in this meeting"
    uncheck "I'll vote in this meeting"

    click_button "Start"
    assert_text "New meeting added."
    assert_empty Round.last.audiences
  end

  test "voting with a chosen name" do
    fill_in "Title", with: "Board"
    fill_in "Your name in this meeting", with: "Jimmy (Chair)"
    click_button "Start"
    assert_text "New meeting added."
    assert_equal "Jimmy (Chair)", Round.last.audiences.sole.name
  end
end
