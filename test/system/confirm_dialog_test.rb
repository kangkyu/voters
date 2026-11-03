require "application_system_test_case"

class ConfirmDialogTest < ApplicationSystemTestCase
  setup do
    sign_in "john"
    visit user_path(users(:john).another_id)
  end

  test "sign out asks in the app's popup with its own button label" do
    click_button "Sign Out"
    within "dialog#confirm_dialog" do
      assert_text "Signing out as \"john\"?"
      assert_button "Sign out"
      assert_no_button "OK"
      click_button "Cancel"
    end
    assert_no_selector "dialog#confirm_dialog[open]"
    assert_button "Sign Out"

    click_button "Sign Out"
    within("dialog#confirm_dialog") { click_button "Sign out" }
    assert_no_button "Sign Out"
  end
end
