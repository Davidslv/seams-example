# frozen_string_literal: true

ActiveRecord::Schema[8.1].define(version: 0) do
  create_table :teams do |t|
    t.string :name, null: false
    t.string :slug, null: false
    t.timestamps
  end
  add_index :teams, :slug, unique: true
  
  create_table :team_memberships do |t|
    t.references :team,    null: false
    t.bigint     :user_id, null: false
    t.string     :role,    null: false, default: "member"
    t.timestamps
  end
  add_index :team_memberships, %i[team_id user_id], unique: true
  
  create_table :team_invitations do |t|
    t.references :team,        null: false
    t.string     :email,       null: false
    t.string     :token,       null: false
    t.string     :role,        null: false, default: "member"
    t.datetime   :expires_at,  null: false
    t.datetime   :accepted_at
    t.timestamps
  end
  add_index :team_invitations, :token, unique: true
  add_index :team_invitations, %i[team_id email], unique: true,
                                                  where: "accepted_at IS NULL"
  
  create_table :users do |t|
    t.string :email
    t.timestamps
  end
end
