# frozen_string_literal: true

# This file is the demo: run `bin/rails db:seed` and you'll watch the
# seams event bus fire end-to-end against the Wave 9 Identity / Account
# model.
#
# It creates:
#   1. an Auth::Identity                 (the human + their credentials)
#   2. an Accounts::Account              (the tenant) via create_with_owner
#   3. publishes user.onboarded.example  (subscriber logs to dev.log)
#   4. an in_app Notifications::Notification owned by the Identity
#   5. a Billing::Plan + Billing::Subscription on the Account
#   6. a Teams::Team + owner Membership + a pending Invitation
#
# Re-run safe: `find_or_create_by!` / `find_or_initialize_by` keeps a
# single demo Identity + Account + Team across repeated `db:seed`
# invocations.

email = "demo+seams@example.com"
puts "[seed] Creating Auth::Identity with email=#{email}..."
identity = Auth::Identity.find_or_create_by!(email: email) do |identity_record|
  identity_record.password = "verysecret-demo-password"
end

puts "[seed] Creating (or fetching) Accounts::Account 'Seams Demo Workspace'..."
demo_account_name = "Seams Demo Workspace"
account = Accounts::Account.find_by(name: demo_account_name)
if account.nil?
  OwnerStruct = Struct.new(:identity, :name) unless defined?(OwnerStruct)
  account = Accounts::Account.create_with_owner(
    account: { name: demo_account_name },
    owner:   OwnerStruct.new(identity, "Demo Owner")
  )
  puts "[seed]   Created Account id=#{account.id}; system + owner memberships seeded."
else
  puts "[seed]   Reusing existing Account id=#{account.id}."
end

puts "[seed] Publishing user.onboarded.example..."
Seams::Events::Publisher.publish(
  "user.onboarded.example",
  identity_id: identity.id,
  account_id:  account.id,
  email:       identity.email,
  source:      "db:seed"
)

puts "[seed] Registering 'default' notification type + delivering in_app notification..."
Notifications::TypeRegistry.register("default",
                                     template: "default", channels: %i[in_app])
notification = identity.notify(strategy: :in_app, template: "default")

puts "[seed] Notification id=#{notification.id} owner=#{notification.owner_type}##{notification.owner_id}"
puts "[seed] Identity now has #{identity.unread_in_app_notifications.count} unread in_app notification(s)."

puts "[seed] Seeding a demo Plan + Subscription on the Account (no live Stripe call)..."
plan = Billing::Plan.find_or_create_by!(gateway_ref: "price_demo_seams") do |plan_record|
  plan_record.name         = "Demo Plan"
  plan_record.amount_cents = 2900
  plan_record.currency     = "GBP"
  plan_record.interval     = "month"
end
unless Billing::Subscription.exists?(account_id: account.id, plan_ref: plan.gateway_ref)
  Billing::Subscription.create!(
    gateway_ref:        "sub_demo_seams_#{SecureRandom.hex(4)}",
    account_id:         account.id,
    customer_ref:       "cus_demo_seams",
    plan_ref:           plan.gateway_ref,
    status:             "active",
    current_period_end: 30.days.from_now
  )
  puts "[seed]   Created demo Subscription on Account id=#{account.id}."
end

puts "[seed] Seeding a demo Team + owner Membership + a pending Invitation..."
team = Teams::Team.find_or_create_by!(slug: "seams-demo-team") do |team_record|
  team_record.name = "Seams Demo Team"
end
unless Teams::Membership.exists?(team_id: team.id, identity_id: identity.id)
  Teams::Membership.create!(team_id: team.id, identity_id: identity.id, role: "owner")
  puts "[seed]   Added Identity id=#{identity.id} as owner of Team id=#{team.id}."
end
unless Teams::Invitation.exists?(team_id: team.id, email: "invitee+seams@example.com", accepted_at: nil)
  invitation = Teams::Invitation.create!(
    team_id: team.id,
    email:   "invitee+seams@example.com",
    role:    "member"
  )
  puts "[seed]   Created pending Invitation token=#{invitation.token[0, 8]}... expires_at=#{invitation.expires_at}."
end

puts "[seed] Done."
puts "[seed]   Tail log/development.log to see the [example] subscriber line."
puts "[seed]   Try: bin/rails console then `Auth::Identity.first`, `Accounts::Account.first`, `Teams::Team.first`."
