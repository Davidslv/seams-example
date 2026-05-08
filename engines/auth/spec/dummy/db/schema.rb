# frozen_string_literal: true

ActiveRecord::Schema[8.1].define(version: 0) do
  create_table :auth_users do |t|
    t.text    :email,            null: false
    t.string  :password_digest,  null: false
    t.bigint  :host_user_id
    t.string  :password_reset_token
    t.datetime :password_reset_token_sent_at
    t.timestamps
  end
  add_index :auth_users, :email, unique: true
  add_index :auth_users, :password_reset_token, unique: true,
                                                where: "password_reset_token IS NOT NULL"
  
  create_table :auth_sessions do |t|
    t.references :user,       null: false, foreign_key: { to_table: :auth_users }
    t.string     :token,      null: false
    t.datetime   :expires_at, null: false
    t.timestamps
  end
  add_index :auth_sessions, :token, unique: true
  
  create_table :auth_oauth_providers do |t|
    t.references :user,         null: false, foreign_key: { to_table: :auth_users }
    t.string     :provider,     null: false
    t.text       :provider_uid, null: false
    t.text       :access_token
    t.text       :refresh_token
    t.datetime   :expires_at
    t.string     :token_type,   default: "Bearer"
    t.jsonb      :profile_data, null: false, default: {}
    t.timestamps
  end
  add_index :auth_oauth_providers, %i[provider provider_uid], unique: true
  add_index :auth_oauth_providers, %i[user_id provider],      unique: true
  
  create_table :auth_api_tokens do |t|
    t.references :user,         null: false, foreign_key: { to_table: :auth_users }
    t.string     :name,         null: false
    t.string     :token_digest, null: false
    t.string     :token_prefix, null: false
    t.datetime   :expires_at
    t.datetime   :last_used_at
    t.timestamps
  end
  add_index :auth_api_tokens, :token_digest, unique: true
end
