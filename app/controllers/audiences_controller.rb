class AudiencesController < ApplicationController
  before_action :set_round

  def new
    if @round.audiences.exists?(user_id: current_user.id)
      redirect_to round_url(@round), notice: "User already joined as attendee" and return
    end
    @audience = @round.audiences.build
  end

  def create
    @audience = @round.audiences.build(audience_params.merge(user_id: current_user.id))

    if @audience.save
      redirect_to round_contestants_url(@round)
    else
      render 'new', status: :unprocessable_entity
    end
  end

  private

  def audience_params
    params.require(:audience).permit(:name)
  end

  def set_round
    @round = Round.find_by(another_id: params[:round_id])
  end
end
