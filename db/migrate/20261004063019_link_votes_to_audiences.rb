class LinkVotesToAudiences < ActiveRecord::Migration[7.0]
  def up
    # Each vote belongs to the voter's audience record in the agenda item's meeting
    execute <<~SQL
      UPDATE votes SET audience_id = audiences.id
      FROM contestants, audiences
      WHERE votes.audience_id IS NULL
        AND contestants.id = votes.contestant_id
        AND audiences.round_id = contestants.round_id
        AND audiences.user_id = votes.user_id
    SQL

    change_column_null :votes, :audience_id, false
    remove_index :votes, [ :audience_id, :contestant_id ]
    add_index :votes, [ :audience_id, :contestant_id ], unique: true
    add_foreign_key :votes, :audiences
  end

  def down
    remove_foreign_key :votes, :audiences
    remove_index :votes, [ :audience_id, :contestant_id ]
    add_index :votes, [ :audience_id, :contestant_id ]
    change_column_null :votes, :audience_id, true
  end
end
