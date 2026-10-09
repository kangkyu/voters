class RenameContestantsToAgendaItems < ActiveRecord::Migration[8.1]
  def change
    # A meeting's agenda holds items of different kinds (motions, elections), not contestants
    rename_table :contestants, :agenda_items
    rename_column :votes, :contestant_id, :agenda_item_id
  end
end
