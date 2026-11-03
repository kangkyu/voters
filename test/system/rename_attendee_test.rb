require "application_system_test_case"

class RenameAttendeeSystemTest < ApplicationSystemTestCase
  test "the organizer renames an attendee in place" do
    visit signin_path
    fill_in "username", with: "jimmy"
    fill_in "password", with: "1111"
    click_button "Sign In"
    assert_text "Hello \"jimmy\""
    visit owner_round_audiences_path(rounds(:meeting))

    row = find("tr", text: "Johnny")
    within(row) do
      click_link "Rename"
      fill_in "Attendee Name", with: "John Smith"
      click_button "Save"
      assert_text "“John Smith”"
      assert_link "Rename"
    end
    assert_equal "John Smith", audiences(:john_at_meeting).reload.name
  end
end
