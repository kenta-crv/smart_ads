class CampaignsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_campaign, only: [:show, :edit, :update, :destroy, :send_campaign]

  def index
    @campaigns = current_user.campaigns.order(created_at: :desc)
  end

  def show; end

  def new
    @campaign = current_user.campaigns.build
  end

  def create
    @campaign = current_user.campaigns.build(campaign_params)
    if @campaign.save
      redirect_to user_campaigns_path(current_user), notice: "Campaign created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @campaign.update(campaign_params)
      redirect_to user_campaigns_path(current_user), notice: "Campaign updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.destroy
    redirect_to user_campaigns_path(current_user), notice: "Campaign deleted successfully."
  end

  def send_campaign
    @campaign = Campaign.find(params[:id])
    
    # Simulate sending
    @campaign.update(status: "sending")

    # Create a new push subscription for the user (simulated)
    new_subscription = @campaign.user.push_subscriptions.create!(
      endpoint: "https://dummy.push.service/#{SecureRandom.uuid}",
      keys: { p256dh: SecureRandom.hex(16), auth: SecureRandom.hex(8) },
      browser: "Chrome",
      status: "active"
    )

    # Record results for all active subscriptions
    @campaign.user.push_subscriptions.where(status: "active").each do |sub|
      CampaignResult.create!(
        campaign: @campaign,
        push_subscription: sub,
        status: "completed",
        delivered_at: Time.current
      )
    end

    @campaign.update(status: "completed")

    redirect_to user_campaigns_path(@campaign.user), notice: "Campaign sent successfully!"
  end

  private

  def set_campaign
    @campaign = current_user.campaigns.find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(
      :title, :body, :icon_url, :target_url,
      :targeting_conditions, :scheduled_at, :status
    )
  end
end
