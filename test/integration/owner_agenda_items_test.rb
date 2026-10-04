require "test_helper"

class OwnerAgendaItemsTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:contest)
    post session_path, params: { username: "jimmy", password: "1111" }
  end

  test "owner sees agenda items and the add form" do
    get owner_round_contestants_path(@round)
    assert_response :success
    assert_select "ol#admin_contestants li##{ActionView::RecordIdentifier.dom_id(contestants(:singer))} h3", "singer"
    assert_select "aside form#new_contestant_form"
  end

  test "owner adds an agenda item and gets a fresh form" do
    assert_difference "Contestant.count", 1 do
      post owner_round_contestants_path(@round), params: { contestant: { name: "Budget", location: "Q3" } }, as: :turbo_stream
    end
    assert_select "turbo-stream[action=append][target=admin_contestants] h3", "Budget"
    assert_select "turbo-stream[action=replace][target=new_contestant_form] input[name='contestant[name]']:not([value])"
  end

  test "owner deletes an agenda item" do
    contestant = contestants(:singer)
    assert_difference "Contestant.count", -1 do
      delete owner_round_contestant_path(@round, contestant), as: :turbo_stream
    end
    assert_select "turbo-stream[action=remove][target=#{ActionView::RecordIdentifier.dom_id(contestant)}]"
  end
end
