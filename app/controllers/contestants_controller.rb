class ContestantsController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_audience

  def index
    @contestants = @round.contestants.order(:created_at)
    if @contestants.any?
      @contestants = @audience.assign_my_votes_to_contestants(@contestants)
    end
  end
end
