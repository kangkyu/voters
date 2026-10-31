class Owner::PasscodesController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_owner

  # Turns the passcode on, or replaces it with a new one
  def create
    @round.regenerate_passcode!
    redirect_to round_url(@round, anchor: "passcode"), notice: t("flash.passcode_created", passcode: @round.passcode)
  end

  def destroy
    @round.update!(passcode: nil)
    redirect_to round_url(@round, anchor: "passcode"), notice: t("flash.passcode_off")
  end

  def require_owner
    if !owner_user?
      redirect_to user_url(current_user.another_id), notice: t("flash.owner_only")
    end
  end

  def owner_user?
    signed_in? && current_user.owner?(@round)
  end
end
