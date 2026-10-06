class AddDecisionMadeToContestants < ActiveRecord::Migration[8.1]
  def change
    # Set by the owner; once true, attendees can no longer vote on the item
    add_column :contestants, :decision_made, :boolean, default: false, null: false
  end
end
