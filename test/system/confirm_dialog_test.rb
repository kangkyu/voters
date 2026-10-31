require "application_system_test_case"

class ConfirmDialogTest < ApplicationSystemTestCase
  setup do
    visit signin_path
    fill_in "username", with: "john"
    fill_in "password", with: "1111"
    click_button "Sign In"
    assert_no_text "Not logged in"
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
