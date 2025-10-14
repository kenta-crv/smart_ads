class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :push_subscriptions, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :campaign_results, through: :campaigns
  has_one :install_script, dependent: :destroy

  # Validations
  validates :first_name, :last_name, presence: true
  # validates :api_key, uniqueness: true

  # Methods
  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def client?
    true
  end
end
