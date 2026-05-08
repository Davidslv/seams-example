# Changelog

This is the host application's CHANGELOG. The seams gem (`gem "seams", path: "../seams"`)
has its own waves; the entries below describe the *demo*'s state at each
sync point — what the canonical engines ship, what the host wires, and
what a reader of this repo can expect to see working.

## Unreleased — Wave 9 baseline

Regenerated from scratch against `seams` main post Wave 9. Wave 9
broke the "Auth::User as both human + tenant" assumption: there are
now three peer engines — `auth`, `accounts`, `teams` — each with one
clear responsibility.

### Major changes vs the Wave 8 baseline

- **Identity rename.** `Auth::User` (on `auth_users`) is now
  `Auth::Identity` (on `auth_identities`). The new table is its own
  thing, separate from any host-defined User. Once Identity has its
  own table the historical Rails 8 `has_secure_password reset_token`
  naming clash is gone — Auth uses the built-in
  `password_reset_token` signed_id, no `reset_token: false` workaround.
- **New `accounts` engine.** `Accounts::Account` (UUID primary key,
  the tenant) and `Accounts::Membership` (joins Identity ↔ Account
  with role enum: `owner` / `admin` / `member` / `system`). Provides
  `Accounts::Current` per-request namespace, `Accounts::AccountScoped`
  model concern, `Accounts::Authorization` controller concern, and
  `Account.create_with_owner` which seeds a system actor + an owner
  membership in one transaction.
- **Teams repointed.** `Teams::Membership` joins `Auth::Identity`
  directly via `identity_id`. Teams are peers to Accounts, not
  nested. The host-User `Teams::Teamable` concern is gone — there's
  no canonical demo User to mix it into.
- **Notifications repointed at Identity.** `NotificationPreference`
  keys off `identity_id` (channel preferences belong with the human,
  not the tenant). The `AuthSubscriber` listens for
  `identity.signed_up.auth` (renamed from `user.signed_up.auth`). The
  `Notifiable` concern is OPTIONAL — wired onto `Auth::Identity` in
  the demo via Pattern A in `config/initializers/notifications.rb`.
- **Billing repointed at Account.** Subscriptions / Invoices /
  LifetimePasses all carry `account_id` (UUID); `customer_ref` (the
  Stripe `cus_*` id) lives alongside it. The `Billing::Billable`
  concern is auto-included on `Accounts::Account` via
  `Billing.configuration.billable_class` (default
  `"Accounts::Account"`). Canonical billing event payloads now key on
  `account_id` next to `customer_ref`.
- **No host `User`.** The Wave 8 demo's `app/models/user.rb` (which
  mixed in four concerns) is gone. Hosts that want a domain User
  with extra columns keep their own model; the canonical demo
  doesn't.

### Engines

**Core** — host concerns (`Auditable`, `SoftDeletable`, `Sluggable`,
`TenantScoped`, `HasCurrentAttributes`), the `core_audit_logs` table,
`Core::EventPublisher`, and the shared email format validator.

**Auth** — bcrypt-backed `Auth::Identity` on its own
`auth_identities` table, session cookies, API tokens with prefix
indexing, OAuth (Google + GitHub via Faraday) under the
`Auth::OAuth::*` namespace, password reset via Rails 8
`has_secure_password` `password_reset_token` (a signed_id, NOT a
column), PII column encryption (email + provider_uid + access tokens)
via `ActiveRecord::Encryption`.

**Accounts** — `Accounts::Account` (UUID PK), `Accounts::Membership`
(role enum incl. system actor for audit-log writes), `Accounts::Current`,
`AccountScoped` + `Authorization` concerns. No controllers ship —
hosts drive their own account-creation flow. Auto-publishes
`account.created.accounts`, `account.cancelled.accounts`,
`membership.created.accounts`, `membership.role_changed.accounts`,
`membership.removed.accounts`.

**Notifications** — `Notification` polymorphic model + per-Identity
preferences + delivery records, three channel strategies (`in_app`
via Turbo Streams, `email` via ActionMailer, `sms` stub),
schedulable notifications with `next_delivery_at`, type registry +
mailer layout. The `BillingSubscriber` resolves the recipient via
`Billing.configuration.billable_class` (default `Accounts::Account`)
so per-Account billing notifications land on the tenant directly.

**Billing** — `Plan` / `Subscription` / `Invoice` / `WebhookEvent` /
`LifetimePass` models (all keyed on `account_id`), Stripe gateway
built on the official `stripe` gem (~> 13), 13 webhook handlers
across customer/subscription/invoice/payment_intent/charge/checkout,
`Billing::Lifetime::GrantPassService` + `RevokePassService` with
pessimistic row locking, `seams:billing:check_config` rake task.

**Teams** — `Team` + `Membership` (joins Identity via
`identity_id`) + `Invitation` (with token + accept flow),
`Teams::AccountScoped` concern.

### Host

- `db/seeds.rb` is a working demo: creates an Identity, an Account
  (via `create_with_owner`), publishes the host's
  `user.onboarded.example` event, delivers an in-app notification to
  the Identity, seeds a demo Plan + Subscription on the Account.
- `config/initializers/example_events.rb` registers
  `user.onboarded.example` AND attaches a logging subscriber so the
  full register-subscribe-publish loop is visible. Payload now carries
  `identity_id` + `account_id` (no more `user_id`).
- `config/initializers/notifications.rb` activates Pattern A —
  `Auth::Identity.include(Notifications::Notifiable)` on `to_prepare`
  — so `identity.notify(...)` is the demo's Notifiable surface.
- `config/initializers/active_record_encryption.rb` ships throwaway
  dev/test keys so `bin/rails db:setup` boots without a manual key
  generation step. Replace with credential-stored values for any
  real-PII host.
- `spec/host_boot_spec.rb` exercises the new Identity → Account
  round-trip end-to-end.
- CI runs lint (rubocop) + security (brakeman + bundle-audit) +
  per-engine spec matrix + host spec; each job clones the seams
  repo as a sibling so the path source resolves.

### Intentionally omitted

- **No host `User` model.** See above — Wave 9 splits the
  responsibilities. Add one in your own host if you have profile
  columns the canonical engines don't carry.
- **AdminUser scaffold**: per the seams docs, regular users and
  admins belong on separate tables. Use `Auth::Identity#staff?` for
  the bare-bones platform-admin predicate; build a separate
  `admin_identities` table when you need richer admin auth.

## Wave 8 baseline (historical)

> The heading below was originally labelled "Wave 11 baseline" by a
> drafting error — the entry actually describes the demo's state
> against seams Wave 8 (the predecessor of the Wave 9 rework above).
> Renamed for clarity; the body is unchanged.

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
