# app/controllers/install_scripts_controller.rb
class InstallScriptsController < ApplicationController
  before_action :set_user

  def show
    @install_script = @user.install_script || @user.create_install_script!(
      script_code: "<script src='https://smartads.com/push.js?api_key=#{@user.api_key}'></script>"
    )
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
