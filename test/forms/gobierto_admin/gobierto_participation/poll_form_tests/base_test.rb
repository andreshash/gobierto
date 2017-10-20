# frozen_string_literal: true

require 'test_helper'

module GobiertoAdmin
  module GobiertoParticipation
    module PollFormTests
      class BaseTest < ActiveSupport::TestCase

        def site
          @site ||= sites(:madrid)
        end

        def admin
          @admin ||= gobierto_admin_admins(:tony)
        end

      end
    end
  end
end
