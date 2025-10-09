class CreatePushSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true # client
      t.string :endpoint, null: false
      t.jsonb :keys, null: false, default: {}
      t.string :browser, null: false
      t.string :status, null: false, default: "active" # active, expired, revoked
      t.timestamps
    end

    add_index :push_subscriptions, :endpoint, unique: true
  end
end
