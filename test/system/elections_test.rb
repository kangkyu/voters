require "application_system_test_case"

class ElectionsTest < ApplicationSystemTestCase
  test "owner adds an election from the agenda form" do
    sign_in "jimmy"

    visit owner_round_agenda_items_path(rounds(:meeting))
    within "#new_agenda_item_form" do
      assert_no_field "Candidates"
      assert_field "Decision vote"

      select "Election (pick one candidate)", from: "Type"
      assert_no_field "Decision vote"
      fill_in "Title", with: "Chair"
      fill_in "Candidates", with: "Ann\nBob"
      click_on "Add"
    end

    within "#admin_agenda_items" do
      assert_text "Election · 2 candidates"
      assert_text "Ann and Bob"
    end
  end
end
