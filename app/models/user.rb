class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :push_subscriptions, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :campaign_results, through: :campaigns
  has_one :install_script, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_one :active_subscription, -> { where(status: :active) }, class_name: "Subscription"
  has_many :payments, dependent: :destroy

  validates :first_name, :last_name, presence: true
  # validates :api_key, uniqueness: true

  # Methods
  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def client?
    true
  end

  def current_subscription
    active_subscription || subscriptions.order(created_at: :desc).first
  end

  def on_trial?
    subscription_plan == "trial" && trial_ends_at.present? && trial_ends_at > Time.current
  end

  def subscription_active?
    subscription_status == "active"
  end

  def can_send_campaign?(recipient_count)
    return false unless subscription_active?
    sub = current_subscription
    return false unless sub
    sub.can_send_delivery?(recipient_count)
  end

  after_create :initialize_trial_subscription, if: :new_record?

  private

  def initialize_trial_subscription
    subscriptions.create!(
      plan_type: :trial,
      status: :active,
      trial_ends_at: 15.days.from_now
    )
    update(
      subscription_plan: "trial",
      subscription_status: "active",
      trial_ends_at: 15.days.from_now
    )
  end
end
