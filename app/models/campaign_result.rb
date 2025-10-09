class CampaignResult < ApplicationRecord
  belongs_to :campaign
  belongs_to :push_subscription

  validates :status, presence: true
end
