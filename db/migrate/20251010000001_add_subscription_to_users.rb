class AddSubscriptionToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :subscription_plan, :string, default: "trial"
    add_column :users, :subscription_status, :string, default: "active"
    add_column :users, :trial_ends_at, :datetime
    add_column :users, :payjp_customer_id, :string
    add_index :users, :subscription_plan
    add_index :users, :subscription_status
  end
end

