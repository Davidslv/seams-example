# frozen_string_literal: true

# Force-load this engine's lib/ so the constant resolves whether rspec
# is run from the host root (`bundle exec rspec engines/billing/spec`)
# or from inside the engine. The host's spec_helper does not require us.
# Rails must load before lib/billing.rb because engine.rb references
# Rails::Engine.
require "rails"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "billing"

RSpec.describe Billing do
  it "defines a VERSION constant" do
    expect(Billing::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
