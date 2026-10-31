class RenameLocationToSubtitleOnAgendaItems < ActiveRecord::Migration[8.1]
  def change
    rename_column :agenda_items, :location, :subtitle
  end
end
