class AddElectionsToAgendaItems < ActiveRecord::Migration[8.1]
  def change
    # An agenda item is a motion (favor / against) or an election (pick one candidate)
    add_column :agenda_items, :kind, :integer, default: 0, null: false

    create_table :candidates do |t|
      t.references :agenda_item, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end

    # A motion vote has a choice; an election vote has a candidate instead
    add_reference :votes, :candidate, foreign_key: true
    change_column_null :votes, :choice, true
    change_column_default :votes, :choice, from: 0, to: nil
  end
end
