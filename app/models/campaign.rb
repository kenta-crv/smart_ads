class Campaign < ApplicationRecord
  belongs_to :user
  has_many :campaign_results, dependent: :destroy

  validates :title, :body, :status, presence: true

  enum status: { draft: "draft", scheduled: "scheduled", sending: "sending", completed: "completed" }

end
