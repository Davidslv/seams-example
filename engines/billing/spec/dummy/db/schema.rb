# frozen_string_literal: true

ActiveRecord::Schema[8.1].define(version: 0) do
  create_table :billing_subscriptions do |t|
    t.string   :customer_ref,       null: false
    t.string   :plan_ref,           null: false
    t.string   :gateway_ref,        null: false
    t.string   :status,             null: false, default: "incomplete"
    t.datetime :current_period_end
    t.timestamps
  end
  add_index :billing_subscriptions, :gateway_ref, unique: true
  
  create_table :billing_invoices do |t|
    t.string     :gateway_ref,      null: false
    t.string     :customer_ref,     null: false
    t.string     :subscription_ref
    t.integer    :amount_cents,     null: false
    t.string     :currency,         null: false, default: "USD"
    t.string     :status,           null: false, default: "open"
    t.datetime   :paid_at
    t.timestamps
  end
  add_index :billing_invoices, :gateway_ref, unique: true
  
  create_table :billing_webhook_events do |t|
    t.string   :gateway,           null: false
    t.string   :gateway_event_id,  null: false
    t.string   :event_type,        null: false
    t.boolean  :livemode,          null: false, default: false
    t.timestamps
  end
  add_index :billing_webhook_events, %i[gateway gateway_event_id], unique: true
  
  create_table :billing_plans do |t|
    t.string  :gateway_ref,       null: false
    t.string  :name,              null: false
    t.text    :description
    t.integer :amount_cents,      null: false, default: 0
    t.string  :currency,          null: false, default: "usd"
    t.string  :interval,          null: false, default: "month"
    t.integer :trial_period_days
    t.boolean :active,            null: false, default: true
    t.jsonb   :features,          null: false, default: {}
    t.integer :max_lifetime_units
    t.timestamps
  end
  
  create_table :billing_lifetime_passes do |t|
    t.string   :customer_ref,        null: false
    t.string   :plan_ref,            null: false
    t.string   :gateway_ref
    t.bigint   :granted_by_user_id
    t.datetime :granted_at,          null: false
    t.datetime :revoked_at
    t.bigint   :revoked_by_user_id
    t.text     :notes
    t.timestamps
  end
  add_index :billing_lifetime_passes, %i[customer_ref plan_ref], unique: true,
                                                                 name: "index_billing_ltd_unique"
  
  create_table :users do |t|
    t.string :email
    t.string :stripe_customer_id
    t.timestamps
  end
end
