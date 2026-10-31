class VotesController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_audience
  before_action :find_agenda_item
  before_action :require_voting_open
  before_action :require_not_voted

  # Casts my vote: favor / against on a motion, a candidate in an election, or abstain on either.
  # Like a paper ballot, it's final: there is no changing or withdrawing it afterwards.
  def create
    attributes = vote_attributes
    return head :unprocessable_entity unless attributes

    @agenda_item.my_vote = @agenda_item.votes.create!(attributes.merge(audience: @audience, user: current_user))
    render_votes
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # A concurrent request (double click, second tab) cast my vote first: that one stands
    @agenda_item.my_vote = @agenda_item.votes.find_by(audience: @audience) || raise
    render_votes status: :unprocessable_entity
  end

  private

  # nil when the request doesn't name a valid choice for this agenda item
  def vote_attributes
    if @agenda_item.election? && params[:choice] == "abstain"
      { choice: "abstain", candidate: nil }
    elsif @agenda_item.election?
      candidate = @agenda_item.candidates.find_by(id: params[:candidate_id])
      { candidate: candidate, choice: nil } if candidate
    elsif Vote.choices.key?(params[:choice])
      { choice: params[:choice] }
    end
  end

  def find_agenda_item
    @agenda_item = @round.agenda_items.find(params[:agenda_item_id])
  end

  def render_votes(status: :ok)
    render partial: "activity/votes", locals: { agenda_item: @agenda_item }, status: status
  end

  # Once the owner marks the decision made, answer with the closed buttons instead
  def require_voting_open
    return unless @agenda_item.decision_made?

    @agenda_item.my_vote = @agenda_item.votes.find_by(audience: @audience)
    render_votes status: :unprocessable_entity
  end

  # Already voted on this item: answer with my vote as it stands
  def require_not_voted
    vote = @agenda_item.votes.find_by(audience: @audience)
    return unless vote

    @agenda_item.my_vote = vote
    render_votes status: :unprocessable_entity
  end
end
