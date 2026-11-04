require "test_helper"

# The organizer can delete a meeting at any time; a popup says what goes with it
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

  test "with others attending, the popup counts what goes, and deleting takes it all" do
    attendee = audiences(:john_at_meeting)
    agenda_items(:item).votes.create!(audience: attendee, user: attendee.user, choice: "favor")
    sign_in "jimmy"
    get round_path(@round)
    assert_select "form[action='#{round_path(@round)}'][data-confirm-detail=?]",
      "This also deletes 2 attendees, 1 vote and its agenda items."

    assert_difference -> { Round.count } => -1, -> { Audience.count } => -2, -> { Vote.count } => -1 do
      delete round_path(@round)
    end
    assert_redirected_to user_url(users(:jimmy).another_id)
    assert User.exists?(attendee.user_id), "accounts stay"
  end

  test "an attendee on the voting page of a deleted meeting is sent home" do
    sign_in "john"
    @round.destroy!
    get round_agenda_items_path(@round)
    assert_redirected_to root_url
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
