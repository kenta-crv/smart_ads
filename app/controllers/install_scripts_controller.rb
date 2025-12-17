# app/controllers/install_scripts_controller.rb
class InstallScriptsController < ApplicationController
  before_action :set_user

  def show
    base_url = request.base_url
    @install_script = @user.install_script || @user.create_install_script!(
      script_code: generate_embed_script(base_url)
    )
  end

  private

  def generate_embed_script(base_url)
    <<~SCRIPT
      <script>
        (function() {
          var script = document.createElement('script');
          script.src = '#{base_url}/embed.js?api_key=#{@user.api_key}';
          script.async = true;
          document.head.appendChild(script);
        })();
      </script>
    SCRIPT
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
