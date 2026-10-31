class RoundsController < ApplicationController
  before_action :require_signin

  def new
    @round = Round.new(organizer_name: current_user.username)
  end

  def create
    @round = current_user.rounds.build(round_params)

    # :organize also requires the organizer's attendee name when they vote; they join under it on save
    if @round.save(context: [:create, :organize])
      redirect_to round_url(@round.reload), notice: t("flash.meeting_created")
    else
      flash.now[:alert] = t("flash.meeting_create_failed")
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @round = Round.find_by(another_id: params[:id])
    unless @round.present?
      redirect_to root_url, alert: t("flash.meeting_not_found")
    end
  end

  private

  def round_params
    params.require(:round).permit(:title, :require_passcode, :organizer_votes, :organizer_name)
  end
end
