# Abstain is no longer a choice. Its votes (choice 2) go, so those attendees count as not voted,
# and each agenda item's vote counter is recounted to match
class RemoveAbstainVotes < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM votes WHERE choice = 2"
    execute <<~SQL
      UPDATE agenda_items
      SET votes_count = (SELECT COUNT(*) FROM votes WHERE votes.agenda_item_id = agenda_items.id)
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
