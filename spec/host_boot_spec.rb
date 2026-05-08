# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Host application boot" do
  it "loads all canonical engines via the seams path source" do
    expect(defined?(Auth::Engine)).to          eq("constant")
    expect(defined?(Billing::Engine)).to       eq("constant")
    expect(defined?(Core::Engine)).to          eq("constant")
    expect(defined?(Notifications::Engine)).to eq("constant")
    expect(defined?(Teams::Engine)).to         eq("constant")
  end

  describe "the example event bus loop" do
    it "delivers user.onboarded.example to the subscriber wired in config/initializers/example_events.rb" do
      expect(Seams::EventRegistry.registered?("user.onboarded.example")).to be(true)

      logs = []
      allow(Rails.logger).to receive(:info) { |line| logs << line }

      Seams::Events::Publisher.publish(
        "user.onboarded.example",
        user_id: 42,
        email:   "spec@example.com",
        source:  "host_boot_spec"
      )

      example_lines = logs.grep(/\[example\] user\.onboarded\.example/)
      expect(example_lines).not_to be_empty,
                                   "Expected the [example] subscriber to log; saw: #{logs.inspect}"
      expect(example_lines.first).to include("user_id: 42")
      expect(example_lines.first).to include('"spec@example.com"')
    end
  end

  describe User do
    it "demonstrates that all four canonical concerns mix in cleanly" do
      user = described_class.new
      expect(user).to respond_to(:auth_user)
      expect(user).to respond_to(:billing_subscriptions)
      expect(user).to respond_to(:notify)
      expect(user).to respond_to(:teams)
    end
  end
end
