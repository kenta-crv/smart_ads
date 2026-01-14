class MakeCampaignOptionalInPayments < ActiveRecord::Migration[7.1]
  def change
    change_column_null :payments, :campaign_id, true
  end
end

