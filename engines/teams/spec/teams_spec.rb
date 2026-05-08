# frozen_string_literal: true

# Force-load this engine's lib/ so the constant resolves whether rspec
# is run from the host root (`bundle exec rspec engines/teams/spec`)
# or from inside the engine. The host's spec_helper does not require us.
# Rails must load before lib/teams.rb because engine.rb references
# Rails::Engine.
require "rails"
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "teams"

RSpec.describe Teams do
  it "defines a VERSION constant" do
    expect(Teams::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
