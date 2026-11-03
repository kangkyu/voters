require "application_system_test_case"

class NewMeetingTest < ApplicationSystemTestCase
  setup do
    sign_in "jimmy"
    visit new_round_path
  end

  test "unticking voting hides the name, and the meeting starts without it" do
    fill_in "Title", with: "Board"
    assert_field "Your name in this meeting", with: "jimmy"

    uncheck "I'll vote in this meeting"
    # Hiding the field moves the Start button up: wait for that before clicking
    assert_no_field "Your name in this meeting"

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
