# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

# Rails has to load before the engine's lib/<name>.rb runs,
# because engine.rb references Rails::Engine. Specs that need
# ActiveRecord should `require "rails_helper"` instead — that
# ALSO boots the dummy app, defines the schema, and connects
# to the test DB.
require "rails"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "billing"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
