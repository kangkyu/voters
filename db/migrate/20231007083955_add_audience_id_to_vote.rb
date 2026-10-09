class AddAudienceIdToVote < ActiveRecord::Migration[7.0]
  def change
    add_column :votes, :audience_id, :bigint, foreign_key: true
    add_index :votes, [:audience_id, :contestant_id]
    remove_index :votes, :user_id
  end
end
