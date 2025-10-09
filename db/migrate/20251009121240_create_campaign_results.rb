class CreateCampaignResults < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_results do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :push_subscription, null: false, foreign_key: true
      t.string :status, null: false # delivered, clicked, failed
      t.datetime :delivered_at
      t.datetime :clicked_at
      t.string :error_message
      t.timestamps
    end

    add_index :campaign_results, :status
  end
end
