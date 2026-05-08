# seams-example

[![CI](https://github.com/Davidslv/seams-example/actions/workflows/ci.yml/badge.svg)](https://github.com/Davidslv/seams-example/actions/workflows/ci.yml)

A reference Rails 8 host that wires the six canonical engines from
[**seams**](https://github.com/Davidslv/seams) — a CLI framework for
building Rails applications as a modular monolith. The point of this
repo is to be the simplest possible answer to *"what does a project
that uses seams actually look like?"*.

The seams gem itself is loaded as a sibling **path source**:

```ruby
gem "seams", path: "../seams"
```

so this host always tracks `seams` `main` without waiting on a release
cadence. CI clones the gem as a sibling repo for the same reason —
see `.github/workflows/ci.yml`.

## What's wired in

Wave 9 reshaped the model. The "human" is now `Auth::Identity` (its
own table, owns credentials only), the "tenant" is `Accounts::Account`
(its own table, the billing customer), and the join is
`Accounts::Membership` with a role enum. Every other engine addresses
those two by id — there is no host `User` model in the canonical
demo.

| Engine          | Provides                                                                                                                              |
| ---             | ---                                                                                                                                   |
| `core`          | Host concerns: `Auditable`, `SoftDeletable`, `Sluggable`, `TenantScoped`. Audit log table.                                             |
| `auth`          | `Auth::Identity` on `auth_identities`, sessions, password reset (Rails 8 `has_secure_password reset_token`), API tokens, OAuth (Google + GitHub). |
| `accounts`      | `Accounts::Account` (UUID PK) + `Accounts::Membership` (Identity ↔ Account, roles: owner/admin/member/system). `create_with_owner` seeds a system actor. |
| `notifications` | Polymorphic `Notification` model, per-Identity channel preferences, three strategies (in_app via Turbo, email via ActionMailer, sms stub). Optional `Notifiable` concern. |
| `billing`       | Plans, subscriptions, invoices, lifetime passes — all keyed on `account_id`. 13 Stripe webhook handlers via the official `stripe` gem. `Billing::Billable` is auto-included on `Accounts::Account`. |
| `teams`         | Team + membership (joins `Auth::Identity` directly) + invitation flow. Teams are peers to Accounts post-Wave-9, not nested.            |

Each engine ships its own README under `engines/<name>/README.md`.

## Quickstart

```bash
git clone --recurse-submodules git@github.com:Davidslv/seams.git ../seams   # sibling path source
git clone git@github.com:Davidslv/seams-example.git
cd seams-example
bundle install
bin/rails db:setup           # create + migrate + seed
bin/rails s                  # localhost:3000
```

## First five minutes

The most useful thing to do after setup is to watch the **event bus**
fire end-to-end:

```bash
bin/rails db:seed
```

That runs `db/seeds.rb`, which:

1. Creates an `Auth::Identity` (`demo+seams@example.com`)
2. Creates an `Accounts::Account` ("Seams Demo Workspace") via
   `Accounts::Account.create_with_owner` — seeds a system actor + an
   owner `Accounts::Membership` in one transaction
3. Publishes the host's `user.onboarded.example` event — the
   subscriber wired in `config/initializers/example_events.rb` logs
   the payload to `log/development.log`
4. Calls `identity.notify(strategy: :in_app, template: "default")` — a
   `Notification` row is created against the Identity (Pattern A from
   the notifications engine's initializer mixes `Notifiable` onto
   `Auth::Identity`)
5. Creates a demo `Billing::Plan` + `Billing::Subscription` against
   the Account so `account.has_active_billing?` returns true
6. Creates a demo `Teams::Team` + owner `Teams::Membership` (joining
   the Identity directly) + a pending `Teams::Invitation`

Then in `bin/rails console`:

```ruby
identity = Auth::Identity.first
identity.unread_in_app_notifications.count                  # => 1
identity.notify(strategy: :in_app, template: "default")     # → another one
account = Accounts::Account.first
account.memberships.pluck(:role)                            # => ["system", "owner"]
account.has_active_billing?                                 # => true
team = Teams::Team.first
team.memberships.pluck(:role)                               # => ["owner"]
team.invitations.pending.count                              # => 1
Seams::EventRegistry.all.keys                               # → every registered event
```

## Tests

Each engine has its own spec suite + dummy app, matching what
`bin/rails generate seams:<name>` produces from the gem.

```bash
bundle exec rspec spec                                    # host
bundle exec rspec --default-path engines/auth/spec engines/auth/spec
# or via the CLI shim:
bin/rails seams:test[auth]
```

CI runs the matrix in parallel — see `.github/workflows/ci.yml` for the
full job graph (lint → security → discover → per-engine → host).

## Layout

```
seams-example/
├── app/
│   └── models/
│       └── .keep                     # NO host User post-Wave-9; comment explains why
├── config/initializers/
│   ├── example_events.rb             # full register-subscribe-publish demo
│   ├── notifications.rb              # Pattern A: Notifiable onto Auth::Identity
│   ├── active_record_encryption.rb   # throwaway dev/test PII keys
│   ├── seams.rb                      # adapter selection
│   └── auth.rb / accounts.rb / ...   # per-engine config stubs
├── engines/
│   ├── accounts/
│   ├── auth/
│   ├── billing/
│   ├── core/
│   ├── notifications/
│   └── teams/
├── db/seeds.rb                       # Identity → Account → Team event-bus walkthrough
├── spec/host_boot_spec.rb            # behavioural round-trip through the bus
├── doc/ARCHITECTURE.md               # generated by `seams:install`
├── CHANGELOG.md                      # what's in this baseline + what's omitted
└── .github/workflows/ci.yml
```

## Intentionally omitted

This demo concentrates on the consumer-facing six-engine wiring. A
couple of choices a real production host would make are out of scope
on purpose:

- **No host `User` model.** Wave 9 split the conflated "who logs in /
  who pays / who has a profile" trio into three peer engines. The
  canonical demo addresses humans through `Auth::Identity` and
  tenants through `Accounts::Account`. Hosts that want a domain User
  (extra columns the canonical engines don't ship — display name,
  avatar, locale, etc.) keep their own model alongside Identity and
  reference it themselves; that's intentional and out of scope here.
- **No AdminUser scaffold.** Per the seams pattern, regular users and
  admin users belong on separate tables (separate authentication
  boundary, separate audit overlay). Adding one is the same recipe
  as the auth engine, repeated against `admin_identities`. Until then
  use `Auth::Identity#staff?` for platform-admin checks.
- **No deployment.** `Dockerfile` + `config/deploy.yml` are kept as
  Rails defaults. Real deploys (Kamal, Fly, Render, Heroku) are
  outside the scope of "what does seams look like".

## Reference

- [seams gem](https://github.com/Davidslv/seams) — the framework + generators
- [`doc/ARCHITECTURE.md`](doc/ARCHITECTURE.md) — boundaries + flow diagram
- [`CHANGELOG.md`](CHANGELOG.md) — what each baseline includes
- [Modular Rails: Architecture for the Long Game](https://davidslv.uk/modular-rails/) — the book this pattern is from
