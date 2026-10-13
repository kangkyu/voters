module ApplicationHelper
  def class_name_by_tab(path)
    if current_page?(path)
      return "text-gray-900 dark:text-white"
    end
    "text-gray-600 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white"
  end
end
