class RoundsController < ApplicationController
  before_action :require_signin, except: :show

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

  # The meeting link. Anyone not signed in signs up first (or signs in, linked from there). The organizer gets the meeting
  # page, attendees go straight to voting, and anyone else to the join page, to tap Attend (with the
  # passcode, if the meeting has one)
  def show
    @round = Round.find_by(another_id: params[:id])
    return redirect_to(root_url, alert: t("flash.meeting_not_found")) unless @round

    unless signed_in?
      # Signing up or in comes back here, through intended_url. Sign-up first: most new arrivals by link have no account
      session[:intended_url] = request.url
      return redirect_to(register_url, notice: t("flash.register_to_join", title: @round.title))
    end
    return if current_user.owner?(@round)
    return redirect_to(round_agenda_items_url(@round)) if current_user.audience?(@round)

    redirect_to new_round_audience_url(@round)
  end

  # Takes its attendees, agenda items and votes with it; the popup says how many
  def destroy
    @round = current_user.rounds.find_by!(another_id: params[:id])
    @round.destroy!
    redirect_to user_url(current_user.another_id), notice: t("flash.meeting_deleted", title: @round.title)
  end

  private

  def round_params
    params.require(:round).permit(:title, :require_passcode, :organizer_votes, :organizer_name)
  end
end
