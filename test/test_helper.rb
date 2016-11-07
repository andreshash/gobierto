ENV["RAILS_ENV"] = "test"
ENV["DOMAIN"] = "127.0.0.1"

require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/rails"
require "minitest/mock"
require "minitest/reporters"
require "database_cleaner"
require "support/site_helpers"

I18n.locale = I18n.default_locale = :en
Time.zone = "UTC"

DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with :truncation

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

ActiveRecord::Migration.check_pending!

class ActiveSupport::TestCase
  include SiteHelpers

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

  include Capybara::DSL

  Capybara.register_driver :poltergeist_custom do |app|
    Capybara::Poltergeist::Driver.new(
      app,
      timeout: 300,
      inspector: ENV["INTEGRATION_INSPECTOR"] == "true",
      debug: ENV["INTEGRATION_DEBUG"] == "true"
    )
  end

  Capybara.javascript_driver = :poltergeist_custom

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end
end