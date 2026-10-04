class Owner::AudiencesController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_owner

  def index
    if @round.present?
      @audiences = @round.audiences.includes(:user).order(:created_at)
    else
      redirect_to user_url(current_user.another_id), notice: "no meetings"
    end
  end

  # def destroy
  #   @audience = @owner.audiences.find(params[:id])
  #   @audience.destroy
  #   # Use destroy.turbo_stream.erb
  # end

  def require_owner
    if !owner_user?
      redirect_to user_url(current_user.another_id), notice: "owner only"
    end
  end

  def owner_user?
    signed_in? && current_user.owner?(@round)
  end

  private

  def set_round
    @round = current_user.rounds.find_by(another_id: params[:round_id])
  end
end
