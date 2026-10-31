class SessionsController < ApplicationController
  before_action :require_signout, only: [:new, :create]

  def new
  end

  def create
    # Usernames are unique regardless of case, so sign-in ignores case too
    user = User.find_by("LOWER(username) = ?", params[:username].to_s.downcase)

    if user && user.authenticate(params[:password])
      intended_url = session[:intended_url]
      # A fresh session on sign-in, so a session id set before it can't be reused
      reset_session
      session[:user_id] = user.id
      redirect_to intended_url || root_url
    else
      flash.now[:alert] = t("flash.sign_in_failed")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_url
  end
end
