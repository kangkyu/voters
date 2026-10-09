require "test_helper"

class RobustnessTest < ActionDispatch::IntegrationTest
  MISSING_ROUND = "00000000-0000-0000-0000-000000000000"

  setup do
    @round = rounds(:contest)
    @agenda_item = agenda_items(:singer)
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "1111" }
  end

  test "logged-out user opening the join link is sent to sign in" do
    get new_round_audience_path(@round)
    assert_redirected_to signin_url
  end

  test "unknown meeting id redirects instead of erroring" do
    sign_in "john"
    [round_agenda_items_path(MISSING_ROUND), new_round_audience_path(MISSING_ROUND)].each do |path|
      get path
      assert_redirected_to root_url
    end
    post round_agenda_item_votes_path(MISSING_ROUND, @agenda_item), params: { choice: "favor" }
    assert_redirected_to root_url
  end

  test "voting page keeps an empty list for live additions" do
    sign_in "john"
    @agenda_item.destroy
    get round_agenda_items_path(@round)
    assert_select "ul#audience_agenda_item li", text: "No agenda items"
  end

  test "agenda items are list items, not frames wrapping list items" do
    sign_in "john"
    get round_agenda_items_path(@round)
    assert_select "ul#audience_agenda_item > li##{ActionView::RecordIdentifier.dom_id(@agenda_item)} turbo-frame"
  end

  test "withdrawing an already-withdrawn vote still returns the vote buttons" do
    sign_in "john"
    delete round_agenda_item_vote_path(@round, @agenda_item, 0)
    assert_response :success
    assert_select "turbo-frame##{ActionView::RecordIdentifier.dom_id(@agenda_item)}_votes"
  end

  test "attendee name is escaped on the user page" do
    sign_in "john"
    audiences(:john_at_contest).update_column(:name, "<b id=xss>x</b>")
    get user_path(users(:john).another_id)
    assert_not_includes response.body, "<b id=xss>"
    assert_includes response.body, "&lt;b id=xss&gt;"
  end

  test "stale session for a deleted user acts as signed out" do
    sign_in "john"
    users(:john).destroy
    get new_round_path
    assert_redirected_to signin_url
  end

  test "sign-in error mentions username" do
    sign_in "nobody"
    assert_select "div", text: "Invalid username/password combination."
  end
end
