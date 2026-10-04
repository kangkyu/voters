class SessionsController < ApplicationController
  before_action :require_signout, only: [:new, :create]

  def new
  end

  def create
    user = User.find_by(username: params[:username])

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to session[:intended_url] || root_url
      session[:intended_url] = nil
    else
      flash.now[:alert] = "Invalid email/password combination."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to new_session_url
  end
end
