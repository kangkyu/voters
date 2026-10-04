class Vote < ApplicationRecord
  include ActionView::RecordIdentifier

  belongs_to :user
  belongs_to :contestant, counter_cache: true

  enum choice: { favor: 0, against: 1 }

  after_commit :broadcast_votes_count, on: [:create, :update]
  after_destroy_commit :broadcast_votes_count, unless: :destroyed_by_association

  private

  def broadcast_votes_count
    broadcast_replace_later_to "activity",
      target: "#{dom_id(contestant)}_votes_count",
      partial: "owner/contestants/votes_count",
      locals: { contestant: contestant }
  end
end
