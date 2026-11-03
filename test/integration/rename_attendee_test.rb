require "test_helper"

# The organizer fixes how attendees are listed; attendees can't rename themselves
class RenameAttendeeTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting) # organized by jimmy
    @john = audiences(:john_at_meeting)
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "1111" }
  end

  test "the organizer renames an attendee from the list, keeping their votes" do
    sign_in "jimmy"
    get owner_round_audiences_path(@round)
    assert_select "a[href='#{edit_owner_round_audience_path(@round, @john)}']", "Rename"

    get edit_owner_round_audience_path(@round, @john)
    assert_select "input[name='audience[name]'][value=Johnny]"

    assert_no_difference "Vote.count" do
      patch owner_round_audience_path(@round, @john), params: { audience: { name: "John Smith" } }
    end
    assert_redirected_to owner_round_audiences_url(@round)
    assert_equal "John Smith", @john.reload.name
    assert_equal users(:john), @john.user
  end

  test "the organizer can rename their own attendance too" do
    mine = @round.audiences.create!(user: users(:jimmy), name: "jimmy")
    sign_in "jimmy"
    patch owner_round_audience_path(@round, mine), params: { audience: { name: "Jimmy (Chair)" } }
    assert_equal "Jimmy (Chair)", mine.reload.name
  end

  test "a blank name is refused" do
    sign_in "jimmy"
    patch owner_round_audience_path(@round, @john), params: { audience: { name: " " } }
    assert_response :unprocessable_entity
    assert_select "p", /can't be blank/
    assert_equal "Johnny", @john.reload.name
  end

  test "attendees can't rename anyone, themselves included" do
    sign_in "john"
    patch owner_round_audience_path(@round, @john), params: { audience: { name: "Boss" } }
    assert_equal "Johnny", @john.reload.name
  end

  test "an attendee of another meeting can't be renamed through this one" do
    other = Round.create!(title: "Other", owner: users(:gapbun)).audiences.create!(user: users(:john), name: "J")
    sign_in "jimmy"
    patch owner_round_audience_path(@round, other), params: { audience: { name: "X" } }
    assert_response :not_found
    assert_equal "J", other.reload.name
  end

  test "the account page explains a username change doesn't rename attendees" do
    sign_in "john"
    get edit_user_path(users(:john).another_id)
    assert_select "p", /ask the organizer to change it there/
  end
end
