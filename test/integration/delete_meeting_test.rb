require "test_helper"

# A meeting can be deleted until anyone besides the organizer joins
class DeleteMeetingTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting) # organized by jimmy; john and gapbun have joined
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "tV7qLm2xRz9pWk4d" }
  end

  def leave_only_organizer
    @round.audiences.destroy_all
    @round.audiences.create!(user: users(:jimmy), name: "Chair")
  end

  test "with only the organizer attending, they delete it with its agenda items and votes" do
    leave_only_organizer
    agenda_items(:item).votes.create!(audience: @round.audiences.sole, user: users(:jimmy), choice: "favor")
    sign_in "jimmy"
    get round_path(@round)
    assert_select "form[action='#{round_path(@round)}'] button", "Delete meeting"

    assert_difference -> { Round.count } => -1, -> { AgendaItem.count } => -@round.agenda_items.count, -> { Vote.count } => -1 do
      delete round_path(@round)
    end
    assert_redirected_to user_url(users(:jimmy).another_id)
    assert_equal "Deleted “meeting”.", flash[:notice]
  end

  test "with nobody attending, it can be deleted too" do
    @round.audiences.destroy_all
    sign_in "jimmy"
    assert_difference("Round.count", -1) { delete round_path(@round) }
  end

  test "once someone else joins, there's no delete button and deleting is refused" do
    sign_in "jimmy"
    get round_path(@round)
    assert_select "button", { text: "Delete meeting", count: 0 }

    assert_no_difference("Round.count") { delete round_path(@round) }
    assert_redirected_to round_url(@round)
    assert_equal "Attendees have joined this meeting, so it can't be deleted.", flash[:alert]
  end

  test "only the organizer can delete it" do
    @round.audiences.destroy_all
    sign_in "john"
    assert_no_difference("Round.count") { delete round_path(@round) }
    assert_response :not_found
  end

  test "deleting needs sign-in" do
    @round.audiences.destroy_all
    assert_no_difference("Round.count") { delete round_path(@round) }
    assert_redirected_to signin_url
  end
end
