class AddConstraintsToAudiencesAndVotes < ActiveRecord::Migration[8.1]
  def change
    # One attendee record per user per meeting, enforced by the database too
    add_index :audiences, [:user_id, :round_id], unique: true
    add_foreign_key :votes, :contestants
  end
end
