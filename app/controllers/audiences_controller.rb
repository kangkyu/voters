class AudiencesController < ApplicationController
  before_action :require_signin
  before_action :set_round

  # Passcodes are short, so guessing is slowed per account and per network.
  # The network limit is loose: everyone in the room may share one Wi-Fi address
  rate_limit to: 10, within: 3.minutes, only: :create, name: "join-by-user", by: -> { current_user.id },
    with: -> { redirect_to new_round_audience_url(@round), alert: t("flash.too_many_tries") }
  rate_limit to: 100, within: 10.minutes, only: :create, name: "join-by-ip",
    with: -> { redirect_to new_round_audience_url(@round), alert: t("flash.too_many_tries") }

  def new
    if @round.audiences.exists?(user_id: current_user.id)
      redirect_to round_url(@round), notice: t("flash.already_joined") and return
    end
    @audience = @round.audiences.build
  end

  def create
    @audience = @round.audiences.build(audience_params.merge(user_id: current_user.id))

    # The organizer joins their own meeting without the passcode
    unless current_user.owner?(@round) || @round.passcode_matches?(params[:passcode])
      @audience.errors.add(:base, :incorrect_passcode)
      render "new", status: :unprocessable_entity and return
    end

    if @audience.save
      redirect_to round_agenda_items_url(@round)
    else
      render "new", status: :unprocessable_entity
    end
  end

  private

  def audience_params
    params.require(:audience).permit(:name)
  end
end
