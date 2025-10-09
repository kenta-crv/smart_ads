class PushSubscription < ApplicationRecord
  belongs_to :user

  has_many :campaign_results, dependent: :destroy

  validates :endpoint, presence: true, uniqueness: true
  validates :keys, presence: true
  validates :browser, presence: true

end
