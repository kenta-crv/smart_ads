# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_trial_expiration

  protected

  def after_sign_in_path_for(resource)
    return admin_dashboard_index_path if resource.is_a?(Admin)
    return user_dashboard_index_path if resource.is_a?(User)

    super
  end

  def configure_permitted_parameters
    added_attrs = [:first_name, :last_name, :email, :password, :password_confirmation, :remember_me]
    devise_parameter_sanitizer.permit(:sign_up, keys: added_attrs)
    devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
  end

  def check_trial_expiration
    return unless current_user.present?
    current_user.check_and_upgrade_expired_trial
  end

  private

  def admin_root_path
    admin_dashboard_index_path
  end
end
