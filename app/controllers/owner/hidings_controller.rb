# Hides an agenda item from attendees' voting page (create) or shows it again (destroy),
# so the organizer can prepare items ahead and reveal each one as it comes up
class Owner::HidingsController < ApplicationController
  before_action :require_signin
  before_action :set_round
  before_action :require_owner
  before_action :find_agenda_item

  def create
    @agenda_item.update!(hidden: true)
    render_agenda_item
  end

  def destroy
    @agenda_item.update!(hidden: false)
    render_agenda_item
  end

  private

  def find_agenda_item
    @agenda_item = @round.agenda_items.find(params[:agenda_item_id])
  end

  def render_agenda_item
    render turbo_stream: turbo_stream.replace(@agenda_item, partial: "owner/agenda_items/agenda_item", locals: { agenda_item: @agenda_item })
  end

  def require_owner
    unless current_user.owner?(@round)
      redirect_to user_url(current_user.another_id), notice: t("flash.owner_only")
    end
  end
end
