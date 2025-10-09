class AddClientFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :company_name, :string, null: false, default: ""
    add_column :users, :domain, :string, null: false, default: ""
    add_column :users, :api_key, :string, null: false, default: ""

    add_index :users, :api_key
  end
end
