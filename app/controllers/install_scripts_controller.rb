# app/controllers/install_scripts_controller.rb
class InstallScriptsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :ensure_api_key

  def show
    @base_url = request.base_url
  end

  private

  def set_user
    @user = current_user
  end

  def ensure_api_key
    if @user.api_key.blank?
      @user.update!(api_key: generate_api_key)
    end
  end

  def generate_api_key
    loop do
      key = SecureRandom.hex(32)
      break key unless User.exists?(api_key: key)
    end
  end
end
