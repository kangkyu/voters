require "test_helper"

class LandingPageTest < ActionDispatch::IntegrationTest
  test "landing page is public" do
    get root_path
    assert_response :success
    assert_select "h1", /Every voice counted/
    assert_select "a[href=?]", new_session_path
    assert_select "a[href=?]", register_path
  end

  test "landing page greets a signed-in user" do
    user = users(:jimmy)
    post session_path, params: { username: user.username, password: "1111" }

    get root_path
    assert_response :success
    assert_select "a[href=?]", user_path(user.another_id)
    assert_select "a[href=?]", new_session_path, count: 0
  end
end
