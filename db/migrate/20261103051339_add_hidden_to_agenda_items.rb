class AddHiddenToAgendaItems < ActiveRecord::Migration[8.1]
  def change
    add_column :agenda_items, :hidden, :boolean, default: false, null: false
  end
end
