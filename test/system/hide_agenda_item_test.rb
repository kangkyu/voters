require "application_system_test_case"

class HideAgendaItemSystemTest < ApplicationSystemTestCase
  test "the organizer hides an item and shows it again, in place" do
    sign_in "jimmy"
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
