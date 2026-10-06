class Owner::AudiencesController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_owner

  def index
    @audiences = @round.audiences.includes(:user).order(:created_at)
  end

  def require_owner
    if !owner_user?
      redirect_to user_url(current_user.another_id), notice: "owner only"
    end
  end

  def owner_user?
    signed_in? && current_user.owner?(@round)
  end
end
