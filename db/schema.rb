# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_08_115139) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.bigint "external_account_id", null: false
    t.datetime "incinerated_at"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["cancelled_at"], name: "index_accounts_on_cancelled_at"
    t.index ["external_account_id"], name: "index_accounts_on_external_account_id", unique: true
  end

  create_table "accounts_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "identity_id"
    t.string "name", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["account_id", "identity_id"], name: "index_accounts_memberships_unique", unique: true
    t.index ["account_id", "role"], name: "index_accounts_memberships_on_account_id_and_role"
    t.index ["account_id"], name: "index_accounts_memberships_one_system_per_account", unique: true, where: "((role)::text = 'system'::text)"
    t.index ["identity_id"], name: "index_accounts_memberships_on_identity_id"
  end

  create_table "auth_api_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "identity_id", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.string "token_digest", null: false
    t.string "token_prefix", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_auth_api_tokens_on_expires_at", where: "(expires_at IS NOT NULL)"
    t.index ["identity_id"], name: "index_auth_api_tokens_on_identity_id"
    t.index ["token_digest"], name: "index_auth_api_tokens_on_token_digest", unique: true
  end

  create_table "auth_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "email", null: false
    t.string "password_digest", null: false
    t.boolean "staff", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_auth_identities_on_email", unique: true
    t.index ["staff"], name: "index_auth_identities_on_staff", where: "(staff = true)"
  end

  create_table "auth_oauth_providers", force: :cascade do |t|
    t.text "access_token"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "identity_id", null: false
    t.jsonb "profile_data", default: {}, null: false
    t.string "provider", null: false
    t.text "provider_uid", null: false
    t.text "refresh_token"
    t.string "token_type", default: "Bearer"
    t.datetime "updated_at", null: false
    t.index ["identity_id", "provider"], name: "index_auth_oauth_providers_on_identity_id_and_provider", unique: true
    t.index ["identity_id"], name: "index_auth_oauth_providers_on_identity_id"
    t.index ["provider", "provider_uid"], name: "index_auth_oauth_providers_on_provider_and_provider_uid", unique: true
  end

  create_table "auth_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "identity_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_auth_sessions_on_expires_at"
    t.index ["identity_id"], name: "index_auth_sessions_on_identity_id"
    t.index ["token"], name: "index_auth_sessions_on_token", unique: true
  end

  create_table "billing_invoices", force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.string "customer_ref", null: false
    t.string "gateway_ref", null: false
    t.datetime "paid_at"
    t.string "status", default: "open", null: false
    t.string "subscription_ref"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_billing_invoices_on_account_id"
    t.index ["customer_ref"], name: "index_billing_invoices_on_customer_ref"
    t.index ["gateway_ref"], name: "index_billing_invoices_on_gateway_ref", unique: true
    t.index ["status", "created_at"], name: "index_billing_invoices_on_status_and_created_at"
    t.index ["subscription_ref"], name: "index_billing_invoices_on_subscription_ref", where: "(subscription_ref IS NOT NULL)"
  end

  create_table "billing_lifetime_passes", force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.string "customer_ref", null: false
    t.string "gateway_ref"
    t.datetime "granted_at", null: false
    t.bigint "granted_by_identity_id"
    t.text "notes"
    t.string "plan_ref", null: false
    t.datetime "revoked_at"
    t.bigint "revoked_by_identity_id"
    t.datetime "updated_at", null: false
    t.index ["account_id", "plan_ref"], name: "index_billing_ltd_unique", unique: true
    t.index ["account_id"], name: "index_billing_lifetime_passes_on_account_id"
    t.index ["gateway_ref"], name: "index_billing_lifetime_passes_on_gateway_ref", unique: true, where: "(gateway_ref IS NOT NULL)"
    t.index ["revoked_at"], name: "index_billing_lifetime_passes_on_revoked_at", where: "(revoked_at IS NULL)"
  end

  create_table "billing_plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "amount_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "usd", null: false
    t.text "description"
    t.jsonb "features", default: {}, null: false
    t.string "gateway_ref", null: false
    t.string "interval", default: "month", null: false
    t.integer "max_lifetime_units"
    t.string "name", null: false
    t.integer "trial_period_days"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_billing_plans_on_active"
    t.index ["gateway_ref"], name: "index_billing_plans_on_gateway_ref", unique: true
  end

  create_table "billing_subscriptions", force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.string "customer_ref", null: false
    t.string "gateway_ref", null: false
    t.string "plan_ref", null: false
    t.string "status", default: "incomplete", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_billing_subscriptions_on_account_id"
    t.index ["customer_ref"], name: "index_billing_subscriptions_on_customer_ref"
    t.index ["gateway_ref"], name: "index_billing_subscriptions_on_gateway_ref", unique: true
    t.index ["status"], name: "index_billing_subscriptions_on_status"
  end

  create_table "billing_webhook_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "gateway", null: false
    t.string "gateway_event_id", null: false
    t.boolean "livemode", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_billing_webhook_events_on_event_type"
    t.index ["gateway", "gateway_event_id"], name: "index_billing_webhook_events_on_gateway_and_gateway_event_id", unique: true
  end

  create_table "core_audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id"
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.datetime "created_at", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "updated_at", null: false
    t.index ["action", "created_at"], name: "index_core_audit_logs_on_action_and_created_at"
    t.index ["actor_id"], name: "index_core_audit_logs_on_actor_id"
    t.index ["auditable_type", "auditable_id"], name: "index_core_audit_logs_on_auditable_type_and_auditable_id"
  end

  create_table "notification_deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "notification_id", null: false
    t.datetime "sent_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notification_id"], name: "index_notification_deliveries_on_notification_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.bigint "identity_id", null: false
    t.string "notification_type"
    t.datetime "updated_at", null: false
    t.index ["identity_id", "channel", "notification_type"], name: "index_notification_prefs_unique", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "next_delivery_at"
    t.string "owner_id", null: false
    t.string "owner_type", null: false
    t.datetime "read_at"
    t.string "recipient"
    t.jsonb "schedule_data"
    t.string "template", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["next_delivery_at"], name: "index_notifications_on_next_delivery_at"
    t.index ["owner_type", "owner_id"], name: "index_notifications_on_owner"
    t.index ["type", "next_delivery_at"], name: "index_notifications_on_type_and_next_delivery_at"
  end

  create_table "team_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.string "role", default: "member", null: false
    t.bigint "team_id", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "email"], name: "index_team_invitations_on_team_id_and_email", unique: true, where: "(accepted_at IS NULL)"
    t.index ["team_id"], name: "index_team_invitations_on_team_id"
    t.index ["token"], name: "index_team_invitations_on_token", unique: true
  end

  create_table "team_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "identity_id", null: false
    t.string "role", default: "member", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["identity_id"], name: "index_team_memberships_on_identity_id"
    t.index ["team_id", "identity_id"], name: "index_team_memberships_on_team_id_and_identity_id", unique: true
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_teams_on_slug", unique: true
  end

  add_foreign_key "accounts_memberships", "accounts"
  add_foreign_key "auth_api_tokens", "auth_identities", column: "identity_id"
  add_foreign_key "auth_oauth_providers", "auth_identities", column: "identity_id"
  add_foreign_key "auth_sessions", "auth_identities", column: "identity_id"
  add_foreign_key "notification_deliveries", "notifications"
  add_foreign_key "team_invitations", "teams"
  add_foreign_key "team_memberships", "teams"
end
