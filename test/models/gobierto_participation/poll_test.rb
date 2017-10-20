require 'test_helper'

module GobiertoCms
  class ProcessTest < ActiveSupport::TestCase

    def published_poll
      @published_poll ||= gobierto_participation_polls(:ordinance_of_terraces_published)
    end

    def draft_poll
      @draft_poll ||= gobierto_participation_polls(:schedules_draft)
    end

    def future_poll
      @future_poll ||= gobierto_participation_polls(:public_spaces_future)
    end
    alias poll future_poll

    def past_poll
      @past_poll ||= gobierto_participation_polls(:noise_problems_past)
    end

    def test_valid
      assert published_poll.valid?
      assert draft_poll.valid?
      assert future_poll.valid?
      assert past_poll.valid?
    end

    def test_prohibit_editing_poll_with_answers
      assert_raises GobiertoParticipation::Poll::PollHasAnswers do
        published_poll.update_attributes(title: 'wadus')
      end
    end

    def test_answerable?
      assert published_poll.answerable?
      refute draft_poll.answerable?
      refute future_poll.answerable?
      refute past_poll.answerable?
    end

    def test_predicted_unique_answers_count
      # total: 28 days, past: 15 days, answers: 23, avg/day: 1.533x
      # prediction: (28*1.533) ~> 42.933 ~> 43
      poll.update_attributes!(starts_at: 15.days.ago, ends_at: 13.days.from_now)
      poll.stubs(:unique_answers_count).returns(23)

      assert_equal 43, poll.predicted_unique_answers_count
    end

    def test_predicted_answers_returns_actual_answers_for_inactive_polls
      assert_equal 0, draft_poll.predicted_unique_answers_count
      assert_equal 0, future_poll.predicted_unique_answers_count
      assert_equal 0, past_poll.predicted_unique_answers_count

      past_poll.stubs(:unique_answers_count).returns(666)
      assert_equal 666, past_poll.predicted_unique_answers_count
    end

    def test_predicted_answers_under_estimation_limit
      poll.update_attributes!(
        starts_at: Time.zone.now, # started today
        ends_at: 10.days.from_now
      )

      assert_nil poll.predicted_unique_answers_count
    end

  end
end
