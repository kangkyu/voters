class Owner::AgendaItemsController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_owner

  def index
    @agenda_items = @round.agenda_items.order(:created_at)
  end

  def result
    @agenda_items = AgendaItem.load_vote_tallies(@round.agenda_items.order(:created_at).to_a)
  end

  def create
    @agenda_item = @round.agenda_items.build(agenda_item_params)
    if @agenda_item.save
      # Use create.turbo_stream.erb
    else
      render "new", status: :unprocessable_entity
    end
  end

  # Toggles "decision made" from the checkbox in each agenda item
  def update
    @agenda_item = @round.agenda_items.find(params[:id])
    @agenda_item.update!(decision_made: params.require(:agenda_item)[:decision_made])
    render partial: "decision_made", locals: { agenda_item: @agenda_item }
  end

  def destroy
    @agenda_item = @round.agenda_items.find(params[:id])
    @agenda_item.destroy
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

  def agenda_item_params
    params.require(:agenda_item).permit(:name, :location, :decision_rule)
  end
end
