require "test_helper"

class AudienceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Turbo::Broadcastable::TestHelper

  test "refreshes the meeting's results when an attendee joins or leaves" do
    round = rounds(:contest)
    audience = nil
    perform_enqueued_jobs do
      audience = round.audiences.create!(user: users(:jimmy), name: "Jim")
    end
    assert_turbo_stream_broadcasts [round, :results], count: 1

    perform_enqueued_jobs do
      audience.destroy!
    end
    assert_turbo_stream_broadcasts [round, :results], count: 2
  end
end
