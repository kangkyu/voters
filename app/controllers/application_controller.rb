class ApplicationController < ActionController::Base
  around_action :switch_locale

  def require_signin
    unless signed_in?
      session[:intended_url] = request.url
      redirect_to signin_url, notice: t("flash.not_signed_in")
    end
  end

  def require_signout
    if signed_in?
      redirect_to user_url(current_user.another_id), notice: t("flash.already_signed_in")
    end
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  helper_method :current_user

  def signed_in?
    !current_user.nil?
  end
  helper_method :signed_in?

  def require_admin
    if !admin_user?
      redirect_to user_url(current_user.another_id), notice: t("flash.admin_only")
    end
  end

  def admin_user?
    signed_in? && current_user.admin?
  end
  helper_method :admin_user?

  def set_round
    @round = Round.find_by(another_id: params[:round_id])
    redirect_to root_url, alert: t("flash.meeting_not_found") unless @round
  end

  def require_audience
    @audience = @round.audiences.find_by(user: current_user)
    unless @audience
      redirect_to new_round_audience_url(@round), notice: t("flash.join_first")
    end
  end

  private

  # The signed-in user's chosen language, else the browser's, else English
  def switch_locale(&action)
    I18n.with_locale(current_user&.locale.presence || browser_locale || I18n.default_locale, &action)
  end

  # First language in Accept-Language (e.g. "ko-KR,ko;q=0.9,en;q=0.8") that the app has
  def browser_locale
    request.headers["Accept-Language"].to_s.scan(/([a-z]{2})(?:-[A-Za-z]+)?(?:;q=([\d.]+))?/i)
      .sort_by.with_index { |(_, q), i| [-(q || 1).to_f, i] }
      .map { |code, _| code.downcase.to_sym }
      .find { |code| I18n.available_locales.include?(code) }
  end
end
