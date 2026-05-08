# frozen_string_literal: true

ActiveRecord::Schema[8.1].define(version: 0) do
  enable_extension "pgcrypto"
  
  create_table :auth_identities do |t|
    t.text    :email,            null: false
    t.string  :password_digest,  null: false
    t.boolean :staff,            null: false, default: false
    t.timestamps
  end
  add_index :auth_identities, :email, unique: true
  add_index :auth_identities, :staff, where: "staff = true"
  
  create_table :accounts, id: :uuid do |t|
    t.string   :name,                 null: false
    t.bigint   :external_account_id,  null: false
    t.datetime :cancelled_at
    t.datetime :incinerated_at
    t.timestamps
  end
  add_index :accounts, :external_account_id, unique: true
  add_index :accounts, :cancelled_at
  
  create_table :accounts_memberships, id: :uuid do |t|
    t.references :account, type: :uuid, null: false,
                           foreign_key: { to_table: :accounts }, index: false
    t.bigint     :identity_id, null: true
    t.string     :name,        null: false
    t.string     :role,        null: false, default: "member"
    t.boolean    :active,      null: false, default: true
    t.datetime   :verified_at
    t.timestamps
  end
  add_index :accounts_memberships, %i[account_id identity_id], unique: true,
                                                               name: "index_accounts_memberships_unique"
  add_index :accounts_memberships, %i[account_id role]
  add_index :accounts_memberships, :identity_id
  # Wave 9 invariant: exactly one system actor per Account.
  add_index :accounts_memberships, :account_id, unique: true,
            where: "role = 'system'",
            name: "index_accounts_memberships_one_system_per_account"
end
