# frozen_string_literal: true

ActiveRecord::Schema[8.1].define(version: 0) do
  create_table :core_audit_logs do |t|
    t.string  :action,         null: false
    t.string  :auditable_type
    t.bigint  :auditable_id
    t.bigint  :actor_id
    t.jsonb   :payload,        null: false, default: {}
    t.timestamps
  end
  add_index :core_audit_logs, %i[auditable_type auditable_id]
  
  create_table :articles do |t|
    t.string   :title
    t.string   :slug
    t.datetime :deleted_at
    t.bigint   :team_id
    t.timestamps
  end
  add_index :articles, :slug, unique: true
  
  create_table :teams do |t|
    t.string :name
    t.string :slug
    t.timestamps
  end
  add_index :teams, :slug, unique: true
end
