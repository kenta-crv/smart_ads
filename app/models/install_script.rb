class InstallScript < ApplicationRecord
  belongs_to :user

  validates :script_code, presence: true
  validates :version, presence: true
end
