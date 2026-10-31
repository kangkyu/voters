require "test_helper"

class OwnerAgendaItemsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include Turbo::Broadcastable::TestHelper

  setup do
    @round = rounds(:meeting)
    post session_path, params: { username: "jimmy", password: "1111" }
  end

  test "owner sees agenda items and the add form" do
    get owner_round_agenda_items_path(@round)
    assert_response :success
    assert_select "ol#admin_agenda_items li##{ActionView::RecordIdentifier.dom_id(agenda_items(:item))} h3", "item"
    assert_select "aside form#new_agenda_item_form"
  end

  test "owner adds an agenda item and gets a fresh form" do
    assert_difference "AgendaItem.count", 1 do
      post owner_round_agenda_items_path(@round), params: { agenda_item: { name: "Budget", subtitle: "Q3" } }, as: :turbo_stream
    end
    assert_select "turbo-stream[action=append][target=admin_agenda_items] h3", "Budget"
    assert_select "turbo-stream[action=replace][target=new_agenda_item_form] input[name='agenda_item[name]']:not([value])"
  end

  test "owner deletes an agenda item" do
    agenda_item = agenda_items(:item)
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
    agenda_item = agenda_items(:item)
    agenda_item.update!(decision_rule: "majority")
    agenda_item.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), choice: "favor")

    get owner_round_results_path(@round)
    assert_select "##{ActionView::RecordIdentifier.dom_id(agenda_item)} .decision-badge", /Passed/
  end

  test "owner opens an agenda item's edit form in place, and cancels" do
    agenda_item = agenda_items(:item)
    target = ActionView::RecordIdentifier.dom_id(agenda_item)
    get edit_owner_round_agenda_item_path(@round, agenda_item), as: :turbo_stream
    assert_select "turbo-stream[action=replace][target=#{target}] input[name='agenda_item[name]'][value=item]"
    assert_select "turbo-stream[action=replace][target=#{target}] select[name='agenda_item[kind]']", 0

    get owner_round_agenda_item_path(@round, agenda_item), as: :turbo_stream
    assert_select "turbo-stream[action=replace][target=#{target}] h3", "item"
  end

  test "owner edits a motion's name, subtitle and decision rule" do
    agenda_item = agenda_items(:item)
    patch owner_round_agenda_item_path(@round, agenda_item),
      params: { agenda_item: { name: "Board chair", subtitle: "NY", decision_rule: "two_thirds", kind: "election" } }, as: :turbo_stream
    agenda_item.reload
    assert_equal ["Board chair", "NY"], [agenda_item.name, agenda_item.subtitle]
    assert agenda_item.two_thirds?
    assert agenda_item.motion?
    assert_select "turbo-stream[action=replace][target=#{ActionView::RecordIdentifier.dom_id(agenda_item)}] h3", "Board chair"
  end

  test "owner sees why an edit was not saved" do
    agenda_item = agenda_items(:item)
    patch owner_round_agenda_item_path(@round, agenda_item), params: { agenda_item: { decision_rule: "unanimous" } }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_select "turbo-stream[action=replace] form li", /Decision vote/
    assert_nil agenda_item.reload.decision_rule
  end

  test "owner changes an election's candidates before anyone votes" do
    election = @round.agenda_items.create!(name: "Chair", kind: "election", candidate_names: "Ann\nBob")
    patch owner_round_agenda_item_path(@round, election), params: { agenda_item: { candidate_names: "Ann\nBo\nCy" } }, as: :turbo_stream
    assert_equal ["Ann", "Bo", "Cy"], election.reload.candidates.map(&:name)
    assert_select "turbo-stream[action=replace]", text: /Election · 3 candidates/
  end

  test "an election's candidates stay once voting has started" do
    election = @round.agenda_items.create!(name: "Chair", kind: "election", candidate_names: "Ann\nBob")
    election.votes.create!(user: users(:john), audience: audiences(:john_at_meeting), candidate: election.candidates.first)

    get edit_owner_round_agenda_item_path(@round, election), as: :turbo_stream
    assert_select "textarea[name='agenda_item[candidate_names]'][disabled]"

    patch owner_round_agenda_item_path(@round, election), params: { agenda_item: { candidate_names: "Cy\nDee" } }, as: :turbo_stream
    assert_response :unprocessable_entity
    assert_equal ["Ann", "Bob"], election.reload.candidates.map(&:name)

    # Renaming the election itself is still fine
    patch owner_round_agenda_item_path(@round, election), params: { agenda_item: { name: "Chairperson" } }, as: :turbo_stream
    assert_equal "Chairperson", election.reload.name
    assert_equal 1, election.votes.count
  end

  test "attendees' agenda refreshes after an edit" do
    agenda_item = agenda_items(:item)
    perform_enqueued_jobs do
      patch owner_round_agenda_item_path(@round, agenda_item), params: { agenda_item: { name: "Duet" } }, as: :turbo_stream
    end
    assert_turbo_stream_broadcasts [@round, :agenda], count: 1
  end
end
