class AudiencesController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :forbid_organizer

  # Passcodes are short, so guessing is slowed per account and per network.
  # The network limit is loose: everyone in the room may share one Wi-Fi address
  rate_limit to: 10, within: 3.minutes, only: :create, name: "join-by-user", by: -> { current_user.id },
    with: -> { redirect_to new_round_audience_url(@round), alert: t("flash.too_many_tries") }
  rate_limit to: 100, within: 10.minutes, only: :create, name: "join-by-ip",
    with: -> { redirect_to new_round_audience_url(@round), alert: t("flash.too_many_tries") }

  # Also for attendees coming back by the meeting link: they tap Attend again, with the passcode if any
  def new
    @audience = find_or_build_audience
  end

  def create
    @audience = find_or_build_audience

    unless @round.passcode_matches?(params[:passcode])
      @audience.errors.add(:base, :incorrect_passcode)
      render "new", status: :unprocessable_entity and return
    end

    # Already attending: the passcode was all there was to check
    if @audience.persisted? || @audience.save
      redirect_to round_agenda_items_url(@round)
    else
      render "new", status: :unprocessable_entity
    end
  end

  private

  # The organizer chose whether to vote when starting the meeting, and that choice is final
  def forbid_organizer
    if current_user.owner?(@round)
      redirect_to round_url(@round), notice: t("flash.organizer_cannot_join")
    end
  end

  # New attendees join under their username
  def find_or_build_audience
    @round.audiences.find_by(user: current_user) || @round.audiences.build(user: current_user, name: current_user.username)
  end
end
