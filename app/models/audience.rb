class Audience < ApplicationRecord
  belongs_to :user
  belongs_to :round
  has_many :votes, dependent: :destroy

  validates :name, presence: true
  validates :user_id, uniqueness: { scope: :round_id }

  # Results show who hasn't voted yet, which changes as attendees join or leave
  after_create_commit -> { broadcast_refresh_later_to [round, :results] }
  after_destroy_commit -> { broadcast_refresh_later_to [round, :results] }

  def assign_my_votes_to_agenda_items(agenda_items)
    my_votes = votes.where(agenda_item: agenda_items)
    agenda_items.collect do |cont|
      cont.my_vote = my_votes.find { |v| v.agenda_item_id == cont.id }
      cont
    end
  end
end
