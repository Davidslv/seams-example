class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email
      t.bigint :auth_user_id

      t.timestamps
    end
    add_index :users, :auth_user_id
  end
end
