require "test_helper"

class DecisionMadeTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Turbo::Broadcastable::TestHelper

  setup do
    @round = rounds(:contest)
    @agenda_item = agenda_items(:singer)
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "1111" }
  end

  def frame_id(suffix) = "#{ActionView::RecordIdentifier.dom_id(@agenda_item)}_#{suffix}"

  test "owner sees the checkbox on the results page only" do
    sign_in "jimmy"
    checkbox = "turbo-frame##{ActionView::RecordIdentifier.dom_id(@agenda_item, :decision_made)} input[type=checkbox][name='agenda_item[decision_made]']"

    get owner_round_results_path(@round)
    assert_select checkbox

    get owner_round_agenda_items_path(@round)
    assert_select checkbox, 0
  end

  test "owner checks and unchecks decision made" do
    sign_in "jimmy"
    patch owner_round_agenda_item_path(@round, @agenda_item), params: { agenda_item: { decision_made: "1" } }
    assert_response :success
    assert @agenda_item.reload.decision_made?
    assert_select "input[type=checkbox][checked]"

    patch owner_round_agenda_item_path(@round, @agenda_item), params: { agenda_item: { decision_made: "0" } }
    assert_not @agenda_item.reload.decision_made?
  end

  test "only the owner can mark a decision made" do
    sign_in "john"
    patch owner_round_agenda_item_path(@round, @agenda_item), params: { agenda_item: { decision_made: "1" } }
    assert_response :redirect
    assert_not @agenda_item.reload.decision_made?
  end

  test "marking a decision made refreshes attendees' voting pages" do
    perform_enqueued_jobs do
      @agenda_item.update!(decision_made: true)
    end
    assert_turbo_stream_broadcasts [@round, :agenda], count: 1
  end

  test "attendee cannot vote, change, or withdraw once the decision is made" do
    vote = @agenda_item.votes.create!(user: users(:john), audience: audiences(:john_at_contest), choice: "favor")
    @agenda_item.update!(decision_made: true)
    sign_in "john"

    post round_agenda_item_votes_path(@round, @agenda_item), params: { choice: "against" }
    assert_response :unprocessable_entity
    assert vote.reload.favor?

    delete round_agenda_item_vote_path(@round, @agenda_item, vote)
    assert_response :unprocessable_entity
    assert Vote.exists?(vote.id)
    assert_select "turbo-frame##{frame_id(:votes)} button[disabled]", 2
  end

  test "attendee page shows closed items with their vote and no active buttons" do
    @agenda_item.votes.create!(user: users(:john), audience: audiences(:john_at_contest), choice: "favor")
    @agenda_item.update!(decision_made: true)
    sign_in "john"

    get round_agenda_items_path(@round)
    assert_select "turbo-frame##{frame_id(:votes)}" do
      assert_select "span", "Decision made"
      assert_select "button[disabled].bg-green-600", "Favor"
      assert_select "form", 0
    end
  end

  test "a vote cannot be saved on a closed item even outside the controller" do
    @agenda_item.update!(decision_made: true)
    vote = @agenda_item.votes.build(user: users(:john), audience: audiences(:john_at_contest), choice: "favor")
    assert_not vote.valid?
  end
end
