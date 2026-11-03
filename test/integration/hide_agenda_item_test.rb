require "test_helper"

# The organizer hides agenda items from attendees, to prepare them ahead and reveal each as it comes up
class HideAgendaItemTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper
  include Turbo::Broadcastable::TestHelper

  setup do
    @round = rounds(:meeting) # organized by jimmy; john attends
    @item = agenda_items(:item)
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "tV7qLm2xRz9pWk4d" }
  end

  test "the organizer hides an item, and it's marked hidden in their list" do
    sign_in "jimmy"
    get owner_round_agenda_items_path(@round)
    assert_select "##{ActionView::RecordIdentifier.dom_id(@item)} button", "Hide"

    post owner_round_agenda_item_hiding_path(@round, @item), as: :turbo_stream
    assert_response :success
    assert @item.reload.hidden?
    assert_select "turbo-stream[action=replace] template" do
      assert_select "span", "Hidden from attendees"
      assert_select "button", "Show"
    end

    delete owner_round_agenda_item_hiding_path(@round, @item), as: :turbo_stream
    assert_not @item.reload.hidden?
    assert_select "turbo-stream template button", "Hide"
  end

  test "attendees don't see hidden items, and see them once shown" do
    @item.update!(hidden: true)
    sign_in "john"
    get round_agenda_items_path(@round)
    assert_select "h2", { text: @item.name, count: 0 }

    @item.update!(hidden: false)
    get round_agenda_items_path(@round)
    assert_select "h2", @item.name
  end

  test "a hidden item takes no votes" do
    @item.update!(hidden: true)
    sign_in "john"
    assert_no_difference "Vote.count" do
      post round_agenda_item_votes_path(@round, @item), params: { choice: "favor" }
    end
    assert_response :not_found
  end

  test "hiding or showing refreshes attendees' voting pages live" do
    assert_turbo_stream_broadcasts([@round, :agenda]) do
      perform_enqueued_jobs { @item.update!(hidden: true) }
    end
  end

  test "votes already cast stay when an item is hidden and shown again" do
    @item.votes.create!(audience: audiences(:john_at_meeting), user: users(:john), choice: "favor")
    sign_in "jimmy"
    assert_no_difference("Vote.count") do
      post owner_round_agenda_item_hiding_path(@round, @item), as: :turbo_stream
      delete owner_round_agenda_item_hiding_path(@round, @item), as: :turbo_stream
    end
  end

  test "only the organizer can hide items" do
    sign_in "john"
    post owner_round_agenda_item_hiding_path(@round, @item), as: :turbo_stream
    assert_not @item.reload.hidden?
  end
end
