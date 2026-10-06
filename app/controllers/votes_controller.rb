class VotesController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_audience
  before_action :find_contestant

  # Sets or changes my vote (favor / against) for the contestant
  def create
    return head :unprocessable_entity unless Vote.choices.key?(params[:choice])

    vote = @contestant.votes.find_or_initialize_by(audience: @audience, user: current_user)
    begin
      vote.update!(choice: params[:choice])
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      # A concurrent request (double click, second tab) created the vote first
      raise unless vote.new_record?
      vote = @contestant.votes.find_by!(audience: @audience)
      vote.update!(choice: params[:choice])
    end
    @contestant.my_vote = vote
    render partial: "activity/votes", locals: { contestant: @contestant }
  end

  def destroy
    # Already withdrawn (e.g. in another tab): still answer with the frame
    @contestant.votes.find_by(audience: @audience)&.destroy!
    render partial: "activity/votes", locals: { contestant: @contestant }
  end

  private

  def find_contestant
    @contestant = @round.contestants.find(params[:contestant_id])
  end
end
