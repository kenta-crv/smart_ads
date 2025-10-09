class CreateCampaigns < ActiveRecord::Migration[7.1]
  def change
    create_table :campaigns do |t|
      t.references :user, null: false, foreign_key: true # client
      t.string :title, null: false
      t.text :body, null: false
      t.string :icon_url
      t.string :target_url
      t.jsonb :targeting_conditions, default: {} # JSON rules
      t.datetime :scheduled_at
      t.string :status, null: false, default: "draft" # draft, scheduled, sending, completed
      t.timestamps
    end

    add_index :campaigns, :status
    add_index :campaigns, :scheduled_at
  end
end
