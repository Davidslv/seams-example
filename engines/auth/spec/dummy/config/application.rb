# frozen_string_literal: true

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

# The engine isn't a published gem; it lives at engines/<name>/.
# Put its lib/ on the load path before requiring its root file.
$LOAD_PATH.unshift File.expand_path("../../../lib", __dir__)
require "auth"

module Dummy
  class Application < Rails::Application
    # Pin root to the dummy app so Rails doesn't walk up
    # and pick up the host application's Rakefile/config.ru.
    config.root = File.expand_path("..", __dir__)

    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.active_support.deprecation = :stderr
    config.action_controller.include_all_helpers = false
  end
end
