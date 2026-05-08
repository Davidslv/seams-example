# frozen_string_literal: true

ActiveRecord::Schema[8.1].define(version: 0) do
  create_table :auth_identities do |t|
    t.text    :email,            null: false
    t.string  :password_digest,  null: false, default: ""
    t.boolean :staff,            null: false, default: false
    t.timestamps
  end
  add_index :auth_identities, :email, unique: true
  add_index :auth_identities, :staff, where: "staff = true"
  
  create_table :notifications do |t|
    t.string  :type,             null: false
    # Polymorphic owner stored as strings so the column holds bigint
    # Identity IDs and UUID Account IDs simultaneously.
    t.string  :owner_type,       null: false
    t.string  :owner_id,         null: false
    t.string  :recipient
    t.string  :template,         null: false
    t.jsonb   :schedule_data
    t.datetime :next_delivery_at
    t.datetime :read_at
    t.timestamps
  end
  add_index :notifications, %i[owner_type owner_id]
  add_index :notifications, :next_delivery_at
  
  create_table :notification_preferences do |t|
    t.bigint  :identity_id,       null: false
    t.string  :channel,           null: false
    t.string  :notification_type
    t.boolean :enabled,           null: false, default: true
    t.timestamps
  end
  add_index :notification_preferences, %i[identity_id channel notification_type], unique: true,
                                                                                   name: "index_notification_prefs_unique"
  
  create_table :notification_deliveries do |t|
    t.references :notification, null: false, foreign_key: true, index: true
    t.datetime   :sent_at,      null: false
    t.timestamps
  end
end
