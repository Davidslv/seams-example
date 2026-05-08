# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Host application boot" do
  it "loads all canonical engines via the seams path source" do
    expect(defined?(Auth::Engine)).to          eq("constant")
    expect(defined?(Accounts::Engine)).to      eq("constant")
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
        identity_id: 42,
        account_id:  "00000000-0000-0000-0000-000000000042",
        email:       "spec@example.com",
        source:      "host_boot_spec"
      )

      example_lines = logs.grep(/\[example\] user\.onboarded\.example/)
      expect(example_lines).not_to be_empty,
                                   "Expected the [example] subscriber to log; saw: #{logs.inspect}"
      expect(example_lines.first).to include("identity_id: 42")
      expect(example_lines.first).to include('"spec@example.com"')
    end
  end

  describe "the Wave 9 Identity / Account round-trip" do
    # Behavioural round-trip: Identity → Account → publish demo event.
    # Mirrors what `db/seeds.rb` does end-to-end so this spec catches
    # regressions in Pattern A wiring (Notifiable on Identity), the
    # accounts engine's `create_with_owner`, and the host event loop.
    it "creates an Identity, owns an Account via create_with_owner, and exercises Notifiable" do
      identity = Auth::Identity.create!(
        email:    "host-boot-#{SecureRandom.hex(2)}@example.com",
        password: "verysecret"
      )

      owner_struct = Struct.new(:identity, :name).new(identity, "Host Boot Owner")
      account = Accounts::Account.create_with_owner(
        account: { name: "Host Boot Co. #{SecureRandom.hex(2)}" },
        owner:   owner_struct
      )

      expect(account).to be_persisted
      expect(account.memberships.where(role: "system").count).to eq(1)
      expect(account.memberships.where(role: "owner",  identity_id: identity.id).count).to eq(1)

      # Notifiable is mixed onto Auth::Identity by the host's
      # config/initializers/notifications.rb (Pattern A).
      expect(identity).to respond_to(:notify)
      notification = identity.notify(strategy: :in_app, template: "default")
      expect(notification).to be_persisted
      expect(notification.owner).to eq(identity)
    end

    it "joins an Identity directly to a Teams::Team via Teams::Membership" do
      # Wave 9 reshape: Teams::Membership joins Auth::Identity directly
      # (no host User in between). This spec catches regressions in the
      # `identity_id` column wiring + the team owner predicate.
      identity = Auth::Identity.create!(
        email:    "host-boot-team-#{SecureRandom.hex(2)}@example.com",
        password: "verysecret"
      )
      team = Teams::Team.create!(name: "Host Boot Team #{SecureRandom.hex(2)}")
      Teams::Membership.create!(team_id: team.id, identity_id: identity.id, role: "owner")

      expect(team.member?(identity.id)).to be(true)
      expect(team.owner_membership.identity_id).to eq(identity.id)
    end
  end
end
