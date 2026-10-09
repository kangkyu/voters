class AgendaItemsController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_audience

  def index
    @agenda_items = @round.agenda_items.order(:created_at)
    if @agenda_items.any?
      @agenda_items = @audience.assign_my_votes_to_agenda_items(@agenda_items)
    end
  end
end
