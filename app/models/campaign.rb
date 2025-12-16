class Campaign < ApplicationRecord
  belongs_to :user
  has_many :campaign_results, dependent: :destroy
  has_many :payments, dependent: :destroy

  validates :title, :body, :status, presence: true

  enum status: { draft: "draft", scheduled: "scheduled", sending: "sending", completed: "completed" }

  def recipient_count
    push_subscriptions.count
  end

  def delivery_cost
    recipient_count * Subscription::DELIVERY_COST
  end
end

