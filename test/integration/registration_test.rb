require "test_helper"

class RegistrationTest < ActionDispatch::IntegrationTest
  test "register with username and password, no phone number" do
    get register_path
    assert_response :success

    assert_difference "User.count", 1 do
      post users_path, params: { user: { username: "newbie", password: "1111" } }
    end
    assert_redirected_to root_path

    follow_redirect!
    assert_response :success
  end
end
