module ApplicationHelper
  def class_name_by_tab(path)
    if current_page?(path)
      return "text-stone-900 dark:text-white"
    end
    "text-stone-600 hover:text-stone-900 dark:text-stone-400 dark:hover:text-white"
  end
end
