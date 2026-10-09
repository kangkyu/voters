require "test_helper"

class OwnerAgendaItemsTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:contest)
    post session_path, params: { username: "jimmy", password: "1111" }
  end

  test "owner sees agenda items and the add form" do
    get owner_round_agenda_items_path(@round)
    assert_response :success
    assert_select "ol#admin_agenda_items li##{ActionView::RecordIdentifier.dom_id(agenda_items(:singer))} h3", "singer"
    assert_select "aside form#new_agenda_item_form"
  end

  test "owner adds an agenda item and gets a fresh form" do
    assert_difference "AgendaItem.count", 1 do
      post owner_round_agenda_items_path(@round), params: { agenda_item: { name: "Budget", location: "Q3" } }, as: :turbo_stream
    end
    assert_select "turbo-stream[action=append][target=admin_agenda_items] h3", "Budget"
    assert_select "turbo-stream[action=replace][target=new_agenda_item_form] input[name='agenda_item[name]']:not([value])"
  end

  test "owner deletes an agenda item" do
    agenda_item = agenda_items(:singer)
    assert_difference "AgendaItem.count", -1 do
      delete owner_round_agenda_item_path(@round, agenda_item), as: :turbo_stream
    end
    assert_select "turbo-stream[action=remove][target=#{ActionView::RecordIdentifier.dom_id(agenda_item)}]"
  end

  test "owner adds a decision vote item" do
    post owner_round_agenda_items_path(@round), params: { agenda_item: { name: "Bylaws", decision_rule: "two_thirds" } }, as: :turbo_stream
    assert AgendaItem.last.two_thirds?
    assert_select "turbo-stream[action=append][target=admin_agenda_items]", text: /2\/3 approve/
  end

  test "result page shows the decision of a decision vote" do
    agenda_item = agenda_items(:singer)
    agenda_item.update!(decision_rule: "majority")
    agenda_item.votes.create!(user: users(:john), audience: audiences(:john_at_contest), choice: "favor")

    get owner_round_results_path(@round)
    assert_select "##{ActionView::RecordIdentifier.dom_id(agenda_item)} .decision-badge", /Passed/
  end
end
