module ApplicationHelper
  def class_name_by_tab(path)
    if current_page?(path)
      return "bg-gray-900 text-white px-3 py-2 rounded-md text-sm font-medium"
    end
    "text-gray-300 hover:bg-gray-700 hover:text-white px-3 py-2 rounded-md text-sm font-medium"
  end

  # "You own “a”, “b” and “c” meeting." with each title linked; text is HTML-escaped
  def user_s_own_rounds(rounds)
    links = rounds.map { |round| link_to("“#{round.title}”", round_path(round)) }
    safe_join([ "You own ", to_sentence(links, last_word_connector: " and "), " meeting." ])
  end

  # "You are an attendee of “a” as “x” and “b” as “y”." with each title linked
  def user_s_audiences(audiences)
    items = audiences.map do |audience|
      safe_join([ link_to("“#{audience.round.title}”", round_path(audience.round)), " as “", audience.name, "”" ])
    end
    safe_join([ "You are an attendee of ", to_sentence(items, last_word_connector: " and "), "." ])
  end
end
