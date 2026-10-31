require "test_helper"

class OwnerAttendeesTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting)
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

  test "owner removes an attendee along with their votes in the meeting" do
    agenda_item = agenda_items(:item)
    agenda_item.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), choice: "favor")

    assert_difference "Audience.count" => -1, "Vote.count" => -1, "User.count" => 0 do
      delete owner_round_audience_path(@round, audiences(:john_at_meeting))
    end
    assert_redirected_to owner_round_audiences_url(@round)
    assert_equal 0, agenda_item.reload.votes_count

    follow_redirect!
    assert_select "tbody td", { text: "“Johnny”", count: 0 }
  end

  test "attendees can't remove each other" do
    delete session_path
    post session_path, params: { username: "john", password: "1111" }
    assert_no_difference "Audience.count" do
      delete owner_round_audience_path(@round, audiences(:gapbun_at_meeting))
    end
  end
end
