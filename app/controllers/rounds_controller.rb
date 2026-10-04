class RoundsController < ApplicationController
  before_action :require_signin

  def new
    @round = Round.new
  end

  def create
    @round = current_user.rounds.build(round_params)

    if @round.save
      redirect_to round_url(@round.reload), notice: "New meeting added."
    else
      flash.now[:alert] = "New meeting adding not successful"
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @round = Round.find_by(another_id: params[:id])
    unless @round.present?
      redirect_to root_url, alert: "Meeting does not exist"
    end
  end

  private

  def round_params
    params.require(:round).permit(:title)
  end
end
