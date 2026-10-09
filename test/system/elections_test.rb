require "application_system_test_case"

class ElectionsTest < ApplicationSystemTestCase
  test "owner adds an election from the agenda form" do
    visit signin_path
    fill_in "username", with: "jimmy"
    fill_in "password", with: "1111"
    click_button "Sign In"
    assert_no_text "Not logged in"

    visit owner_round_agenda_items_path(rounds(:contest))
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
