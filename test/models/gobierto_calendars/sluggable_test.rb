# frozen_string_literal: true

require "test_helper"
require "support/event_helpers"

module GobiertoCalendars
  class SluggableTest < ActiveSupport::TestCase
    include ::EventHelpers

    def test_assign_slug_with_date
      event_1 = create_event(title: "_* (Title)-", starts_at: "2017-01-02 18:00:00")
      event_2 = create_event(title: "_* (Title)--", starts_at: "2017-01-02 20:00:00")
      event_3 = create_event(title: "_* (Title)_2", starts_at: "2017-01-02")

      assert_equal "2017-01-02-title", event_1.slug
      assert_equal "2017-01-02-title-2", event_2.slug
      assert_equal "2017-01-02-title-2-2", event_3.slug
    end
  end
end
