class UsersController < ApplicationController
  before_action :require_signin, only: [:index, :show, :edit, :update]
  before_action :require_admin, only: [:index]
  before_action :require_own_user, only: [:show, :edit, :update]

  def new
    @user = User.new
  end

  def create
    # Start in the language the sign-up page was shown in
    @user = User.new(user_params.merge(locale: I18n.locale.to_s))

    if @user.save
      intended_url = session[:intended_url]
      # Signing up also signs in: start a fresh session, as sign-in does
      reset_session
      session[:user_id] = @user.id
      redirect_to intended_url || root_url
    else
      flash.now[:alert] = t("flash.sign_up_failed", errors: @user.errors.full_messages.to_sentence)
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
      redirect_to user_url(@user.another_id), notice: changing_password ? t("flash.account_and_password_updated") : t("flash.account_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_own_user
    @user = User.find_by(another_id: params[:id])
    redirect_to root_url, notice: t("flash.not_your_page") unless @user && @user == current_user
  end

  def user_params
    params.require(:user).permit(:username, :password)
  end
end
