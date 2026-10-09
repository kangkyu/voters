require "test_helper"

class OwnerFlowTest < ActionDispatch::IntegrationTest
  test "cannot see result before login" do
    round = rounds(:contest)

    get owner_round_results_path(round)
    assert_response :redirect
  end

  test "cannot add round before login" do
    assert_no_difference "Round.count" do
      post rounds_path, params: { round: { title: "concert" } }
    end
  end

  test "member can add round after login" do
    get signin_path
    post session_path, params: { username: "jimmy", password: "1111" }

    assert_difference "Round.count", 1 do
      post rounds_path, params: { round: { title: "concert" } }
    end
    round = Round.last

    follow_redirect!
    assert_equal round_path(round), path
  end

  test "if not owner, member cannot see results after login" do
    get signin_path
    post session_path, params: { username: "jimmy", password: "1111" }

    assert_difference "Round.count", 1 do
      post rounds_path, params: { round: { title: "concert" } }
    end
    round = Round.last

    delete session_path

    get signin_path
    assert_response :success

    https!
    post session_path, params: { username: "gapbun", password: "1111" }

    get owner_round_results_path(round.another_id)
    assert_response :redirect
  end

  test "owner can see results after login" do
    get signin_path
    post session_path, params: { username: "jimmy", password: "1111" }

    assert_difference "Round.count", 1 do
      post rounds_path, params: { round: { title: "concert" } }
    end
    round = Round.last

    get owner_round_results_path(round.another_id)

    assert_response :ok
    assert_select "h2.font-semibold", "“concert” meeting result"
  end

  test "owner sees a copy link button on the meeting page" do
    post session_path, params: { username: "jimmy", password: "1111" }
    round = rounds(:contest)

    get round_path(round)
    assert_select "[data-controller=clipboard] [data-clipboard-target=source]", round.url
    assert_select "button[data-action='clipboard#copy']", "Copy link"
  end
end
