class Owner::AudiencesController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_owner

  def index
    @audiences = @round.audiences.includes(:user).order(:created_at)
  end

  # Takes someone out of this meeting, with their votes in it; their account stays
  def destroy
    audience = @round.audiences.find(params[:id])
    audience.destroy!
    redirect_to owner_round_audiences_url(@round), notice: t("flash.attendee_removed", name: audience.name)
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
