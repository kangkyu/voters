require "test_helper"

class OwnerAttendeesTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:contest)
    post session_path, params: { username: "jimmy", password: "1111" }
  end

  test "owner sees attendees with their usernames" do
    get owner_round_audiences_path(@round)
    assert_response :success
    assert_select "tbody tr", @round.audiences.count
    assert_select "tbody td", "“Johnny”"
    assert_select "tbody td", "john"
  end

  test "owner sees an empty state when nobody has joined" do
    @round.audiences.destroy_all

    get owner_round_audiences_path(@round)
    assert_select "table", 0
    assert_select "p", /No attendees yet/
  end
end
