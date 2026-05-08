# The host's User model. Each `include` below is a *capability* the
# host opts into from one of the canonical seams engines — they're
# mixins, not requirements. A real application might split these
# across User, Account, and Membership models depending on its
# tenancy shape; this demo concentrates them on User to keep the
# wiring obvious.
class User < ApplicationRecord
  # Auth — links to Auth::User (separate table, owns email +
  # password_digest + sessions + api_tokens + oauth providers).
  # Adds the `auth_user` association and `signed_in?` helpers.
  # Reset flow uses the column-based seams generator, NOT Rails 8's
  # has_secure_password reset_token feature.
  include Auth::Authenticatable

  # Billing — gives the User `start_subscription!`, `cancel_subscription!`,
  # `has_active_billing?` and the `billing_subscriptions` /
  # `billing_lifetime_passes` associations. Rails 8 + the official
  # `stripe` gem (~> 13.0) under the hood; webhook handlers in
  # engines/billing/app/services/billing/webhooks/.
  include Billing::Billable

  # Notifications — gives the User `notify(strategy:, template:)` and
  # the `notifications` / `notification_preferences` associations.
  # Strategies are pluggable (in_app via Turbo broadcast, email via
  # ActionMailer, sms stub) and respect per-channel preferences.
  include Notifications::Notifiable

  # Teams — gives the User `teams`, `memberships`, `member_of?(team)`,
  # `admin_of?(team)`, and the invitation accept flow. The Teams
  # engine ships its own AccountScoped concern so engines that need
  # team-aware records (audit logs, invoices) can scope automatically.
  include Teams::Teamable

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email, with: ->(value) { value.to_s.strip.downcase }
end
