class AddPasscodeToRounds < ActiveRecord::Migration[8.1]
  def change
    add_column :rounds, :passcode, :string
  end
end
