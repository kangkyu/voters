class AddDecisionRuleToContestants < ActiveRecord::Migration[8.1]
  def change
    # nil: tally only, 1: majority (more than 1/2), 2: two-thirds (2/3 or more)
    add_column :contestants, :decision_rule, :integer
  end
end
