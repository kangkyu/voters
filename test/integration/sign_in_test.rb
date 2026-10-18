require "test_helper"

class SignInTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:contest)
  end

  test "signs in with the username in any case" do
    post session_path, params: { username: "JoHN", password: "1111" }
    assert_redirected_to root_path
    assert_equal users(:john).id, session[:user_id]
  end

  test "rejects a wrong password" do
    post session_path, params: { username: "john", password: "nope" }
    assert_response :unprocessable_entity
    assert_nil session[:user_id]
  end

  test "goes back to the page that asked for sign-in, then forgets it" do
    get round_agenda_items_path(@round)
    assert_redirected_to signin_url

    post session_path, params: { username: "john", password: "1111" }
    assert_redirected_to round_agenda_items_url(@round)
    assert_nil session[:intended_url]
  end

  test "signing in starts a fresh session" do
    get round_agenda_items_path(@round)
    before = session.id.to_s

    post session_path, params: { username: "john", password: "1111" }
    assert_not_equal before, session.id.to_s
  end

  test "signing out clears the whole session" do
    post session_path, params: { username: "john", password: "1111" }
    delete session_path
    assert_redirected_to new_session_url
    assert_nil session[:user_id]
  end

  test "signing up keeps the page that asked for sign-in" do
    get round_agenda_items_path(@round)
    post users_path, params: { user: { username: "newbie", password: "1111" } }
    assert_redirected_to round_agenda_items_url(@round)
    assert_equal User.find_by(username: "newbie").id, session[:user_id]
  end
end
