require "test_helper"

class LanguageTest < ActionDispatch::IntegrationTest
  setup do
    @round = rounds(:meeting)
    @agenda_item = agenda_items(:item)
  end

  def sign_in(username, headers: {})
    post session_path, params: { username: username, password: "1111" }, headers: headers
  end

  test "visitors get their browser's language, English when it isn't offered" do
    get signin_path, headers: { "Accept-Language" => "ko-KR,ko;q=0.9,en;q=0.8" }
    assert_select "html[lang=ko]"
    assert_select "h1", "로그인"

    get signin_path, headers: { "Accept-Language" => "fr-FR,fr;q=0.9" }
    assert_select "html[lang=en]"
    assert_select "h1", "Sign In"
  end

  test "the browser's preference order decides between offered languages" do
    get signin_path, headers: { "Accept-Language" => "en;q=0.5,ko;q=0.9" }
    assert_select "html[lang=ko]"
  end

  test "a user switches to Korean on their account page, without a password" do
    sign_in "john"
    get user_path(users(:john).another_id)
    assert_select "button[aria-pressed=true]", "English"

    patch language_path, params: { locale: "ko" }
    assert_redirected_to user_url(users(:john).another_id)
    assert_equal "ko", users(:john).reload.locale
    follow_redirect!
    assert_select "html[lang=ko]"
    assert_select "div", "언어를 한국어로 바꿨습니다."
    assert_select "button[aria-pressed=true]", "한국어"
    assert_select "form button", "English"
  end

  test "a user's language wins over the browser's" do
    users(:john).update!(locale: "ko")
    sign_in "john", headers: { "Accept-Language" => "en-US" }
    get round_agenda_items_path(@round), headers: { "Accept-Language" => "en-US" }
    assert_select "html[lang=ko]"
    assert_select "button", "찬성"
    assert_select "form[data-turbo-confirm='투표 후에는 변경하거나 취소할 수 없습니다. 투표하시겠습니까?']"
  end

  test "an unknown language is refused" do
    sign_in "john"
    patch language_path, params: { locale: "xx" }
    assert_response :unprocessable_entity
    assert_nil users(:john).reload.locale
  end

  test "changing language needs sign-in" do
    patch language_path, params: { locale: "ko" }
    assert_redirected_to signin_url
  end

  test "the sign-up form offers both languages, with the page's own preselected" do
    get register_path, headers: { "Accept-Language" => "ko" }
    assert_select "select[name='user[locale]'] option[selected][value=ko]", "한국어"
    assert_select "select[name='user[locale]'] option[value=en]", "English"
    assert_select "label", "언어"
  end

  test "signing up saves the chosen language, even if the page was in another" do
    post users_path, params: { user: { username: "newbie", password: "1111", locale: "ko" } }, headers: { "Accept-Language" => "en" }
    assert_equal "ko", User.find_by(username: "newbie").locale
    follow_redirect!
    assert_select "html[lang=ko]"
  end

  test "signing up with an unknown language shows an error" do
    assert_no_difference "User.count" do
      post users_path, params: { user: { username: "newbie", password: "1111", locale: "xx" } }
    end
    assert_response :unprocessable_entity
  end

  test "signing up without choosing keeps the language the page was shown in" do
    post users_path, params: { user: { username: "새사용자", password: "1111" } }, headers: { "Accept-Language" => "ko" }
    assert_equal "ko", User.find_by(username: "새사용자").locale
  end

  test "validation errors come in the user's language" do
    users(:jimmy).update!(locale: "ko")
    sign_in "jimmy"
    patch owner_round_agenda_item_path(@round, @agenda_item), params: { agenda_item: { decision_rule: "unanimous" } }, as: :turbo_stream
    assert_select "form li", /의결 방식/
  end

  # Missing Korean text raises in tests, so this walks every page in Korean
  test "every page renders in Korean" do
    users(:jimmy).update!(locale: "ko") # organizer of the meeting
    users(:john).update!(locale: "ko")  # attendee
    users(:gapbun).update!(locale: "ko") # admin

    get root_path, headers: { "Accept-Language" => "ko" }
    assert_select "h1", /모든 목소리를/
    get register_path, headers: { "Accept-Language" => "ko" }
    assert_select "h1", "아이디 만들기"

    sign_in "jimmy"
    @agenda_item.update!(decision_rule: "majority")
    @round.agenda_items.create!(name: "Chair", kind: "election", candidate_names: "Ann\nBob")
    [round_path(@round), new_round_path, owner_round_agenda_items_path(@round), owner_round_results_path(@round),
     owner_round_minutes_path(@round), owner_round_audiences_path(@round), user_path(users(:jimmy).another_id),
     edit_user_path(users(:jimmy).another_id), new_round_audience_path(@round)].each do |path|
      get path
      follow_redirect! if response.redirect?
      assert_response :success, path
      assert_select "html[lang=ko]"
    end
    get owner_round_results_path(@round)
    assert_select "span", "아직 투표 없음"

    delete session_path
    sign_in "john"
    [round_path(@round), round_agenda_items_path(@round)].each do |path|
      get path
      assert_response :success, path
    end

    delete session_path
    sign_in "gapbun"
    [users_path, admin_dashboard_path].each do |path|
      get path
      assert_response :success, path
    end
    get users_path
    assert_select "span", "관리자"
  end
end
