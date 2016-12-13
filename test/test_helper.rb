ENV["RAILS_ENV"] = "test"

require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/rails"
require "minitest/mock"
require "minitest/reporters"
require "database_cleaner"
require "spy/integration"
require "webmock/minitest"
require "support/session_helpers"
require "support/site_session_helpers"
require "support/message_delivery_helpers"

if ENV["CI"] || ENV["RUN_COVERAGE"]
  require "simplecov"
  SimpleCov.start "rails" do
    add_filter "app/models/concerns"
    add_filter "app/controllers/concerns"

    add_group "Controllers", "app/controllers"
    add_group "Models", "app/models"
    add_group "Forms", "app/forms"
    add_group "Services", "app/services"
    add_group "Decorators", "app/decorators"
    add_group "Presenters", "app/presenters"
    add_group "Repositories", "app/repositories"
    add_group "PubSub", "app/pub_sub"
    add_group "Jobs", "app/jobs"
    add_group "Policies", "app/policies"
    add_group "Helpers", "app/helpers"
    add_group "Mailers", "app/mailers"
    add_group "Views", "app/views"
  end
end

if ENV["CI"]
  require "codecov"
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

I18n.locale = I18n.default_locale = :en
Time.zone = "UTC"

DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with :truncation

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: "elasticsearch"
)

ActiveRecord::Migration.maintain_test_schema!
ActiveRecord::Migration.check_pending!

class ActiveSupport::TestCase
  include SessionHelpers
  include SiteSessionHelpers
  include ActiveJob::TestHelper

  fixtures :all

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end
end

class ActionDispatch::IntegrationTest
  require "minitest/rails/capybara"
  require "capybara/poltergeist"
  require "support/integration/authentication_helpers"
  require "support/integration/site_session_helpers"
  require "support/integration/matcher_helpers"

  include Capybara::DSL
  include Integration::AuthenticationHelpers
  include Integration::SiteSessionHelpers
  include Integration::MatcherHelpers

  Capybara.register_driver :poltergeist_custom do |app|
    Capybara::Poltergeist::Driver.new(
      app,
      timeout: 300,
      inspector: ENV["INTEGRATION_INSPECTOR"] == "true",
      debug: ENV["INTEGRATION_DEBUG"] == "true"
    )
  end

  Capybara.javascript_driver = :poltergeist_custom
  Capybara.default_host = "http://gobierto.dev"

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
    Capybara.reset_session!
  end
end

class GobiertoControllerTest < ActionDispatch::IntegrationTest
  require "support/integration/request_authentication_helpers"

  include Integration::RequestAuthenticationHelpers
end
