class VotesController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_audience
  before_action :find_agenda_item
  before_action :require_voting_open

  # Sets or changes my vote (favor / against) for the agenda_item
  def create
    return head :unprocessable_entity unless Vote.choices.key?(params[:choice])

    vote = @agenda_item.votes.find_or_initialize_by(audience: @audience, user: current_user)
    begin
      vote.update!(choice: params[:choice])
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      # A concurrent request (double click, second tab) created the vote first
      raise unless vote.new_record?
      vote = @agenda_item.votes.find_by!(audience: @audience)
      vote.update!(choice: params[:choice])
    end
    @agenda_item.my_vote = vote
    render partial: "activity/votes", locals: { agenda_item: @agenda_item }
  end

  def destroy
    # Already withdrawn (e.g. in another tab): still answer with the frame
    @agenda_item.votes.find_by(audience: @audience)&.destroy!
    render partial: "activity/votes", locals: { agenda_item: @agenda_item }
  end

  private

  def find_agenda_item
    @agenda_item = @round.agenda_items.find(params[:agenda_item_id])
  end

  # Once the owner marks the decision made, answer with the closed buttons instead
  def require_voting_open
    return unless @agenda_item.decision_made?

    @agenda_item.my_vote = @agenda_item.votes.find_by(audience: @audience)
    render partial: "activity/votes", locals: { agenda_item: @agenda_item }, status: :unprocessable_entity
  end
end
