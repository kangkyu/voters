module ApplicationHelper
  def class_name_by_tab(path)
    if current_page?(path)
      return "bg-gray-900 text-white px-3 py-2 rounded-md text-sm font-medium"
    end
    "text-gray-300 hover:bg-gray-700 hover:text-white px-3 py-2 rounded-md text-sm font-medium"
  end

  def user_s_own_rounds(rounds)
    length = rounds.length
    sentence = []
    sentence << "You own"
    rounds.each_with_index do |round, index|
      link_round = link_to("“#{round.title}”", round_path(round))
      comma = index < length - 2 ? ',' : ''
      and_at_the_end = index == length - 2 ? ' and' : ''
      sentence.push [link_round, comma, and_at_the_end].join
    end
    sentence << "meeting."
    sentence.join(' ').html_safe
  end

  def user_s_audiences(audiences)
    length = audiences.length
    sentence = []
    sentence << "You are an attendee of"
    audiences.each_with_index do |audience, index|
      link_round = link_to("“#{audience.round.title}”", round_path(audience.round))
      comma = index < length - 2 ? ',' : ''
      and_at_the_end = index == length - 2 ? ' and' : '.'
      as = " as “#{audience.name}”"
      sentence.push [link_round, as, comma, and_at_the_end].join
    end
    sentence.join(' ').html_safe
  end
end
