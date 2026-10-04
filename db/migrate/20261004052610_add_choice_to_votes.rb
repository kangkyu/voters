class AddChoiceToVotes < ActiveRecord::Migration[7.0]
  def change
    # 0: favor, 1: against. Existing (heart) votes become favor.
    add_column :votes, :choice, :integer, default: 0, null: false
  end
end
