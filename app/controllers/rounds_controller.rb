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

  # The meeting link. The organizer gets the meeting page; anyone else is signed in (or signs up),
  # then always goes to the join page and taps Attend (with the passcode, if the meeting has one),
  # attendees included
  def show
    @round = Round.find_by(another_id: params[:id])
    return redirect_to(root_url, alert: t("flash.meeting_not_found")) unless @round

    unless signed_in?
      # Signing in or up comes back here, through intended_url
      session[:intended_url] = request.url
      return redirect_to(signin_url, notice: t("flash.sign_in_to_join", title: @round.title))
    end
    return if current_user.owner?(@round)

    redirect_to new_round_audience_url(@round)
  end

  # Only before anyone but the organizer has joined; takes its agenda items and votes with it
  def destroy
    @round = current_user.rounds.find_by!(another_id: params[:id])
    if @round.deletable?
      @round.destroy!
      redirect_to user_url(current_user.another_id), notice: t("flash.meeting_deleted", title: @round.title)
    else
      redirect_to round_url(@round), alert: t("flash.meeting_has_attendees")
    end
  end

  private

  def round_params
    params.require(:round).permit(:title, :require_passcode, :organizer_votes, :organizer_name)
  end
end
