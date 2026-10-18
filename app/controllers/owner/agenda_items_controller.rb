class Owner::AgendaItemsController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_owner

  def index
    @agenda_items = @round.agenda_items.includes(:candidates).order(:created_at)
  end

  def result
    @agenda_items = AgendaItem.load_vote_tallies(@round.agenda_items.includes(:candidates).order(:created_at).to_a)
  end

  # Print-friendly record of the meeting: attendees and each item's outcome
  def minutes
    @agenda_items = AgendaItem.load_vote_tallies(@round.agenda_items.includes(:candidates).order(:created_at).to_a)
    @audiences = @round.audiences.order(:created_at)
    render layout: "print"
  end

  def create
    @agenda_item = @round.agenda_items.build(agenda_item_params)
    if @agenda_item.save
      # Use create.turbo_stream.erb
    else
      render turbo_stream: turbo_stream.replace("new_agenda_item_form", partial: "form", locals: { round: @round, agenda_item: @agenda_item }),
        status: :unprocessable_entity
    end
  end

  # Cancelling an edit puts the agenda item back as it was
  def show
    @agenda_item = @round.agenda_items.find(params[:id])
    render turbo_stream: turbo_stream.replace(@agenda_item, partial: "agenda_item", locals: { agenda_item: @agenda_item })
  end

  # Turns the agenda item into its edit form, in place
  def edit
    @agenda_item = @round.agenda_items.find(params[:id])
    render turbo_stream: turbo_stream.replace(@agenda_item, partial: "edit_form", locals: { agenda_item: @agenda_item })
  end

  # Either toggles "decision made" from the checkbox on the results page, or saves the edit form
  def update
    @agenda_item = @round.agenda_items.find(params[:id])
    if params.require(:agenda_item).key?(:decision_made)
      @agenda_item.update!(decision_made: params[:agenda_item][:decision_made])
      render partial: "decision_made", locals: { agenda_item: @agenda_item }
    elsif @agenda_item.update(agenda_item_edit_params)
      # Candidates may change without the agenda item itself changing, so refresh attendees here
      @agenda_item.broadcast_refresh_later_to [@round, :agenda]
      render turbo_stream: turbo_stream.replace(@agenda_item, partial: "agenda_item", locals: { agenda_item: @agenda_item })
    else
      render turbo_stream: turbo_stream.replace(@agenda_item, partial: "edit_form", locals: { agenda_item: @agenda_item }),
        status: :unprocessable_entity
    end
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
    params.require(:agenda_item).permit(:name, :location, :kind, :decision_rule, :candidate_names)
  end

  # The kind stays as created: votes already cast are favor / against or for a candidate
  def agenda_item_edit_params
    params.require(:agenda_item).permit(:name, :location, :decision_rule, :candidate_names)
  end
end
