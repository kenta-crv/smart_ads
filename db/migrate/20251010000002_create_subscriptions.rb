class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :plan_type, null: false
      t.string :status, null: false, default: "active"
      t.datetime :trial_ends_at
      t.string :payjp_subscription_id
      t.timestamps
    end

    add_index :subscriptions, :plan_type
    add_index :subscriptions, :status
    add_index :subscriptions, :payjp_subscription_id
  end
end

