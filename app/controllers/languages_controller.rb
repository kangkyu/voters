class LanguagesController < ApplicationController
  before_action :require_signin

  # Saves my language; no password needed, unlike the other account settings
  def update
    locale = params[:locale].to_s
    return head :unprocessable_entity unless I18n.available_locales.map(&:to_s).include?(locale)

    current_user.update!(locale: locale)
    redirect_to user_url(current_user.another_id), notice: I18n.t("flash.language_updated", locale: locale)
  end
end
