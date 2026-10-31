require "application_system_test_case"

class VotesTest < ApplicationSystemTestCase
  setup do
    @round = rounds(:contest)
    @agenda_item = agenda_items(:item)
    visit signin_path
    fill_in "username", with: "john"
    fill_in "password", with: "1111"
    click_button "Sign In"
    assert_no_text "Not logged in"
    visit round_agenda_items_path(@round)
  end

  test "cancel in the popup leaves the vote uncast" do
    click_button "Favor"
    within "dialog#confirm_dialog" do
      assert_text "Your vote is final and can't be changed or withdrawn. Are you sure?"
      assert_text "Your vote: Favor"
      assert_no_text @agenda_item.name
      click_button "Cancel"
    end
    assert_no_selector "dialog#confirm_dialog[open]"
    assert_no_text "Vote cast"
    assert_equal 0, @agenda_item.votes.count
  end

  test "submit in the popup casts the vote, which is then locked" do
    click_button "Favor"
    within("dialog#confirm_dialog") { click_button "Submit" }
    assert_text "Your vote is final."
    assert_selector "button[aria-pressed=true]", text: "Favor"
    assert_selector "button[disabled]", text: "Against"
    assert @agenda_item.votes.sole.favor?
  end
end
