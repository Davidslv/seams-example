# frozen_string_literal: true

ActiveRecord::Schema[8.1].define(version: 0) do
  create_table :users do |t|
    t.string :email, null: false
    t.timestamps
  end
  add_index :users, :email, unique: true
  
  create_table :notifications do |t|
    t.string  :type,             null: false
    t.references :owner,         polymorphic: true, null: false, index: true
    t.string  :recipient
    t.string  :template,         null: false
    t.jsonb   :schedule_data
    t.datetime :next_delivery_at
    t.datetime :read_at
    t.timestamps
  end
  add_index :notifications, :next_delivery_at
  
  create_table :notification_preferences do |t|
    t.bigint  :user_id,           null: false
    t.string  :channel,           null: false
    t.string  :notification_type
    t.boolean :enabled,           null: false, default: true
    t.timestamps
  end
  add_index :notification_preferences, %i[user_id channel notification_type], unique: true,
                                                                               name: "index_notification_prefs_unique"
  
  create_table :notification_deliveries do |t|
    t.references :notification, null: false, foreign_key: true, index: true
    t.datetime   :sent_at,      null: false
    t.timestamps
  end
end
