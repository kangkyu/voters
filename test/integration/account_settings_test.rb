require "test_helper"

# The account page only changes the password: usernames stay put, so attendees aren't confused
class AccountSettingsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    post session_path, params: { username: "john", password: "tV7qLm2xRz9pWk4d" }
  end

  def change_password(**attributes)
    patch user_path(@user.another_id), params: { user: { password_challenge: "tV7qLm2xRz9pWk4d" }.merge(attributes) }
  end

  test "user page links to the change password page, which has no username field" do
    get user_path(@user.another_id)
    assert_select "a[href='#{edit_user_path(@user.another_id)}']", "Change password"

    get edit_user_path(@user.another_id)
    assert_response :success
    assert_select "h1", "Change password"
    assert_select "p", /For signing in as “john”/
    assert_select "input[name='user[username]']", 0
    assert_select "input[name='user[password]'][required]"
    assert_select "input[name='user[password_challenge]'][required]"
  end

  test "the form is laid out the way password managers expect" do
    get edit_user_path(@user.another_id)
    # A username for the password manager, not submitted
    assert_select "input[autocomplete=username][value=john][hidden]:not([name])"
    fields = css_select("input[type=password]").map { |input| input["autocomplete"] }
    assert_equal %w[current-password new-password new-password], fields
  end

  test "changes password with the current one, typed twice" do
    change_password(password: "secret-2026", password_confirmation: "secret-2026")
    assert_redirected_to user_url(@user.another_id)
    assert_equal "Password changed.", flash[:notice]
    assert_equal @user.id, session[:user_id]
    assert @user.reload.authenticate("secret-2026")
  end

  test "the username can't be changed, even by sending it" do
    change_password(username: "johnny", password: "secret-2026", password_confirmation: "secret-2026")
    assert_equal "john", @user.reload.username
  end

  test "a new password is required" do
    change_password(password: "", password_confirmation: "")
    assert_response :unprocessable_entity
    assert_select "li", "Password can't be blank"
    assert @user.reload.authenticate("tV7qLm2xRz9pWk4d")
  end

  test "nothing changes without the right current password" do
    [nil, "", "nope"].each do |challenge|
      patch user_path(@user.another_id), params: { user: { password: "secret-2026", password_confirmation: "secret-2026", password_challenge: challenge }.compact }
      assert_response :unprocessable_entity
      assert_select "li", "Current password is invalid"
    end
    assert @user.reload.authenticate("tV7qLm2xRz9pWk4d")
  end

  test "new passwords must match" do
    change_password(password: "a-new-one", password_confirmation: "another")
    assert_response :unprocessable_entity
    assert_select "li", "New password again doesn't match Password"
    assert @user.reload.authenticate("tV7qLm2xRz9pWk4d")
  end

  test "can't change someone else's password" do
    jimmy = users(:jimmy)
    get edit_user_path(jimmy.another_id)
    assert_redirected_to root_url

    patch user_path(jimmy.another_id), params: { user: { password: "hijack-it", password_confirmation: "hijack-it", password_challenge: "tV7qLm2xRz9pWk4d" } }
    assert_redirected_to root_url
    assert jimmy.reload.authenticate("tV7qLm2xRz9pWk4d")
  end

  test "signed-out visitors can't change anything" do
    delete session_path
    change_password(password: "hijack-it", password_confirmation: "hijack-it")
    assert_redirected_to signin_url
    assert @user.reload.authenticate("tV7qLm2xRz9pWk4d")
  end
end
