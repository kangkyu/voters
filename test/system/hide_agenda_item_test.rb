require "application_system_test_case"

class HideAgendaItemSystemTest < ApplicationSystemTestCase
  test "the organizer hides an item and shows it again, in place" do
    visit signin_path
    fill_in "username", with: "jimmy"
    fill_in "password", with: "1111"
    click_button "Sign In"
    assert_text "Hello \"jimmy\""
    visit owner_round_agenda_items_path(rounds(:meeting))

    item = agenda_items(:item)
    within "##{ActionView::RecordIdentifier.dom_id(item)}" do
      click_button "Hide"
      assert_text "Hidden from attendees"
      click_button "Show"
      assert_no_text "Hidden from attendees"
      assert_button "Hide"
    end
    assert_not item.reload.hidden?
  end
end
