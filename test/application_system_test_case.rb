require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  # Live updates and Stimulus toggles can take a moment on a busy machine; the default 2s flakes
  Capybara.default_max_wait_time = 5
end
