class UsersController < ApplicationController
  before_action :require_signin, only: [:index, :show, :edit, :update]
  before_action :require_admin, only: [:index]
  before_action :require_own_user, only: [:show, :edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      intended_url = session[:intended_url]
      # Signing up also signs in: start a fresh session, as sign-in does
      reset_session
      session[:user_id] = @user.id
      redirect_to intended_url || root_url
    else
      flash.now[:alert] = "Sign up not successful: #{@user.errors.full_messages.to_sentence}"
      render :new, status: :unprocessable_entity
    end
  end

  def index
    @users = User.all
  end

  def show
  end

  def edit
  end

  # Changes the username, and the password when a new one is typed. Either way the
  # current password is needed, so an unattended signed-in browser can't take over the account
  def update
    attributes = params.require(:user).permit(:username, :password, :password_confirmation, :password_challenge)
    # A blank new password means keep the current one
    changing_password = attributes[:password].present?
    attributes = attributes.except(:password, :password_confirmation) unless changing_password
    # has_secure_password only checks the challenge when it's given, so always give it
    attributes[:password_challenge] = attributes[:password_challenge].to_s

    if @user.update(attributes)
      if changing_password
        # A fresh session after the change, as on sign-in
        reset_session
        session[:user_id] = @user.id
      end
      redirect_to user_url(@user.another_id), notice: changing_password ? "Account and password updated." : "Account updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_own_user
    @user = User.find_by(another_id: params[:id])
    redirect_to root_url, notice: "Not your user page" unless @user && @user == current_user
  end

  def user_params
    params.require(:user).permit(:username, :password)
  end
end
