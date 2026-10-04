class Owner::ContestantsController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_owner

  def index
    @contestants = @round.contestants.order(:created_at)
  end

  def result
    @contestants = @round.contestants.order(:created_at)
  end

  def create
    @contestant = @round.contestants.build(contestant_params)
    if @contestant.save
      # Use create.turbo_stream.erb
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def destroy
    @contestant = @round.contestants.find(params[:id])
    @contestant.destroy
    # Use destroy.turbo_stream.erb
  end

  def require_owner
    if !owner_user?
      redirect_to user_url(current_user.another_id), notice: "owner only"
    end
  end

  def owner_user?
    signed_in? && current_user.owner?(@round)
  end

  private

  def contestant_params
    params.require(:contestant).permit(:name, :location)
  end

  def set_round
    @round = Round.find_by(another_id: params[:round_id])
  end
end
