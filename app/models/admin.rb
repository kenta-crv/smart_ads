class Admin < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { admin: 0, super_admin: 1 }

  validate :only_one_super_admin, if: :super_admin?

  def full_name
    [first_name, last_name].compact.join(" ")
  end

  private

  def only_one_super_admin
    if Admin.super_admin.exists? && (new_record? || role_changed_to_super_admin?)
      errors.add(:role, "super_admin already exists")
    end
  end

  def role_changed_to_super_admin?
    will_save_change_to_role? && super_admin?
  end
end
