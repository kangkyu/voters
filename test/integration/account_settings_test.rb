require "test_helper"

class AccountSettingsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    post session_path, params: { username: "john", password: "1111" }
  end

  def update_account(**attributes)
    patch user_path(@user.another_id), params: { user: { username: "john", password_challenge: "1111" }.merge(attributes) }
  end

  test "user page links to the edit page" do
    get user_path(@user.another_id)
    assert_select "a[href='#{edit_user_path(@user.another_id)}']", "Edit account"

    get edit_user_path(@user.another_id)
    assert_response :success
    assert_select "input[name='user[username]'][value=john]"
    assert_select "input[name='user[password_challenge]']"
  end

  test "changes username with the current password, keeping the password" do
    update_account(username: "johnny", password: "", password_confirmation: "")
    assert_redirected_to user_url(@user.another_id)
    @user.reload
    assert_equal "johnny", @user.username
    assert @user.authenticate("1111")
  end

  test "changes password with the current one, typed twice" do
    update_account(password: "secret-2026", password_confirmation: "secret-2026")
    assert_redirected_to user_url(@user.another_id)
    assert_equal @user.id, session[:user_id]
    assert @user.reload.authenticate("secret-2026")
  end

  test "nothing changes without the right current password" do
    [nil, "", "nope"].each do |challenge|
      patch user_path(@user.another_id), params: { user: { username: "johnny", password_challenge: challenge }.compact }
      assert_response :unprocessable_entity
      assert_select "li", "Current password is invalid"
    end
    assert_equal "john", @user.reload.username
  end

  test "username must stay unique, in any case" do
    update_account(username: "JIMMY")
    assert_response :unprocessable_entity
    assert_select "li", "Username has already been taken"
  end

  test "new passwords must match" do
    update_account(password: "a-new-one", password_confirmation: "another")
    assert_response :unprocessable_entity
    assert_select "li", "New password again doesn't match Password"
    assert @user.reload.authenticate("1111")
  end

  test "can't edit someone else's account" do
    jimmy = users(:jimmy)
    get edit_user_path(jimmy.another_id)
    assert_redirected_to root_url

    patch user_path(jimmy.another_id), params: { user: { username: "hijack", password_challenge: "1111" } }
    assert_redirected_to root_url
    assert_equal "jimmy", jimmy.reload.username
  end

  test "signed-out visitors can't change anything" do
    delete session_path
    update_account(username: "hijack")
    assert_redirected_to signin_url
    assert_equal "john", @user.reload.username
  end
end
