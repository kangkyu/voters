require "test_helper"

class AdminFlowTest < ActionDispatch::IntegrationTest
  test "cannot see results before login" do
    get users_path
    assert_response :redirect
  end

  test "admin can see results after login" do
    get signin_path
    assert_response :success

    https!
    post session_path, params: { username: "gapbun", password: "1111" }
    get users_path
    assert_response :success
  end

  test "member cannot see results after login" do
    get signin_path
    post session_path, params: { username: "jimmy", password: "1111" }
    get users_path
    assert_response :redirect

    follow_redirect!
    assert_equal user_path(users(:jimmy).another_id), path

    assert_equal "admin only", flash[:notice]
  end

  test "admin can see their own user page" do
    get signin_path
    post session_path, params: { username: "gapbun", password: "1111" }
    get user_path(users(:gapbun).another_id)
    assert_select "span.rounded-full", "Admin"
  end

  test "member can see their own user page" do
    get signin_path
    post session_path, params: { username: "jimmy", password: "1111" }
    get user_path(users(:jimmy).another_id)
    assert_select "span", "Member"
  end
end
