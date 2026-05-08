# Changelog

This is the host application's CHANGELOG. The seams gem (`gem "seams", path: "../seams"`)
has its own waves; the entries below describe the *demo*'s state at each
sync point — what the canonical engines ship, what the host wires, and
what a reader of this repo can expect to see working.

## Unreleased — Wave 11 baseline

Initial commit. Regenerated from scratch against `seams` main at
[commit `4a8cf91`](https://github.com/Davidslv/seams/commit/4a8cf91)
(Wave 8: per-engine spec coverage + 4-agent audit fixes).

### Engines

**Core** — host concerns (`Auditable`, `SoftDeletable`, `Sluggable`,
`TenantScoped`, `HasCurrentAttributes`), the `core_audit_logs` table,
`Core::EventPublisher`, and the shared email format validator.

**Auth** — bcrypt-backed `Auth::User` on its own `auth_users` table
(deliberately separate from the host `User`), session cookies, API
tokens with prefix indexing, OAuth (Google + GitHub via Faraday) under
the `Auth::OAuth::*` namespace, password reset via column-based token
flow (Rails 8 `has_secure_password reset_token: false` shim so the
Rails 8 instance method doesn't shadow the column), PII column
encryption (email + provider_uid + access tokens) via
`ActiveRecord::Encryption`.

**Notifications** — `Notification` polymorphic model + per-channel
preferences + delivery records, three channel strategies (`in_app`
via Turbo Streams, `email` via ActionMailer, `sms` stub),
schedulable notifications with `next_delivery_at`, type registry +
mailer layout-free `Notifications::ApplicationMailer`.

**Billing** — `Plan` / `Subscription` / `Invoice` / `WebhookEvent` /
`LifetimePass` models, Stripe gateway built on the official `stripe`
gem (~> 13.x; uses the `client.v1.<resource>` shape), 13 webhook
handlers across customer/subscription/invoice/payment_intent/charge/
checkout, `Billing::Lifetime::GrantPassService` + `RevokePassService`
with pessimistic row locking, `seams:billing:check_config` rake task
for pre-deploy STRIPE_SECRET_KEY verification.

**Teams** — `Team` + `Membership` (roles: owner/admin/member) +
`Invitation` (with token + accept flow), `Teams::AccountScoped`
concern for engines that need team-aware records, host-side
helpers `member_of?(team)` / `admin_of?(team)`.

### Host

- `User` mixes in `Auth::Authenticatable`, `Billing::Billable`,
  `Notifications::Notifiable`, `Teams::Teamable` — annotated in
  `app/models/user.rb` to show what each capability unlocks.
- `config/initializers/example_events.rb` registers
  `user.onboarded.example` AND attaches a logging subscriber so the
  full register-subscribe-publish loop is visible.
- `db/seeds.rb` is a working demo: creates a User, publishes the
  example event, delivers an in-app notification.
- `spec/host_boot_spec.rb` exercises a behavioural round-trip
  through the bus, not just constant-existence checks.
- CI runs lint (rubocop) + security (brakeman + bundle-audit) +
  per-engine spec matrix + host spec; each job clones the seams
  repo as a sibling so the path source resolves.

### Intentionally omitted

- **AdminUser scaffold**: per the seams docs, `User` and `AdminUser`
  belong on separate tables. This demo concentrates on the consumer-
  facing five-engine wiring; an admin scaffold (its own model, table,
  authentication boundary) is out of scope. Add one in your own host
  by repeating the auth-engine pattern against an `admin_users` table.
