require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  # Live updates and Stimulus toggles can take a moment on a busy machine; the default 2s flakes
  Capybara.default_max_wait_time = 5

  # Waits for the signed-in nav, so a visit right after this can't overtake the sign-in
  def sign_in(username)
    visit signin_path
    fill_in "username", with: username
    fill_in "password", with: "tV7qLm2xRz9pWk4d"
    click_button "Sign In"
    assert_text "Hello \"#{username}\""
  end
end
