class CreateInstallScripts < ActiveRecord::Migration[7.1]
  def change
    create_table :install_scripts do |t|
      t.references :user, null: false, foreign_key: true
      t.text :script_code, null: false
      t.string :version, default: "1.0"
      t.timestamps
    end
  end
end
