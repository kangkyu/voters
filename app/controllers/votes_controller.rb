class VotesController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_audience
  before_action :find_contestant

  # Sets or changes my vote (favor / against) for the contestant
  def create
    return head :unprocessable_entity unless Vote.choices.key?(params[:choice])

    vote = @contestant.votes.find_or_initialize_by(audience: @audience, user: current_user)
    vote.update!(choice: params[:choice])
    @contestant.my_vote = vote
    render partial: "activity/votes", locals: { contestant: @contestant }
  end

  def destroy
    existing_vote = @contestant.votes.find_by(audience: @audience)
    return unless existing_vote

    existing_vote.destroy!
    render partial: "activity/votes", locals: { contestant: @contestant }
  end

  private

  def find_contestant
    @contestant = @round.contestants.find(params[:contestant_id])
  end

  def set_round
    @round = Round.find_by(another_id: params[:round_id])
  end
end
