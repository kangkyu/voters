require "test_helper"

class ResultItemTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting)
    @first = agenda_items(:item)
    @first.update!(decision_rule: "majority")
    @second = @round.agenda_items.create!(name: "Budget", decision_rule: "majority", created_at: @first.created_at + 1.minute)
  end

  def sign_in(username)
    post session_path, params: { username: username, password: "tV7qLm2xRz9pWk4d" }
  end

  def dom_id(record, prefix = nil) = ActionView::RecordIdentifier.dom_id(record, prefix)

  test "results page links to an item's page only once its decision is made" do
    @second.update!(decision_made: true)
    sign_in "jimmy"
    get owner_round_results_path(@round)
    assert_select "turbo-frame##{dom_id(@second, :decision_made)} a[href='#{owner_round_result_item_path(@round, @second)}'][data-turbo-frame=_top]", "View result →"
    assert_select "turbo-frame##{dom_id(@first, :decision_made)} a", 0
  end

  test "checking decision made answers with the link, and unchecking without it" do
    sign_in "jimmy"
    link = "a[href='#{owner_round_result_item_path(@round, @second)}']"

    patch owner_round_agenda_item_path(@round, @second), params: { agenda_item: { decision_made: "1" } }
    assert_select link, "View result →"

    patch owner_round_agenda_item_path(@round, @second), params: { agenda_item: { decision_made: "0" } }
    assert_select link, 0
  end

  test "an item's page shows its results, numbered as on the agenda, without the checkbox" do
    @second.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), choice: "favor")

    sign_in "jimmy"
    get owner_round_result_item_path(@round, @second)
    assert_response :success

    assert_select "a[href='#{owner_round_results_path(@round)}']", "← Results"
    assert_select "##{dom_id(@second)} > span", "2"
    assert_select "##{dom_id(@second)} h1", "Budget"
    assert_select "##{dom_id(@second)}", /Decision · 1\/2 approve/
    assert_select "##{dom_id(@second)} .tally", /Favor 1\s+Against 0/
    assert_select "##{dom_id(@second)} .tally", /Needs 1\/2 of votes cast in favor/
    assert_select "turbo-frame", 0
    assert_select "##{dom_id(@first)}", 0
  end

  test "results pages don't show the hidden badge" do
    @second.update!(hidden: true)
    sign_in "jimmy"

    get owner_round_results_path(@round)
    assert_select "##{dom_id(@second)} .hidden-from-attendees", 0

    get owner_round_result_item_path(@round, @second)
    assert_select "##{dom_id(@second)} .hidden-from-attendees", 0

    get owner_round_agenda_items_path(@round)
    assert_select "##{dom_id(@second)} .hidden-from-attendees", "Hidden from attendees"
  end

  test "an item's page doesn't update live" do
    sign_in "jimmy"
    get owner_round_result_item_path(@round, @second)
    assert_select "turbo-cable-stream-source", 0
  end

  test "an item's page shows in the organizer's language" do
    users(:jimmy).update!(locale: "ko")
    sign_in "jimmy"
    get owner_round_result_item_path(@round, @second)
    assert_select "a[href='#{owner_round_results_path(@round)}']", "← 결과"
    assert_select "##{dom_id(@second)} .tally", /찬성 0/
    assert_select "##{dom_id(@second)} .tally", /투표수의 1\/2 찬성 필요/
  end

  test "only the organizer can see an item's page" do
    sign_in "john"
    get owner_round_result_item_path(@round, @second)
    assert_response :redirect
  end

  test "an item from another meeting isn't found" do
    other = Round.create!(title: "other", owner: users(:jimmy))
    sign_in "jimmy"
    get owner_round_result_item_path(other, @second)
    assert_response :not_found
  end
end
