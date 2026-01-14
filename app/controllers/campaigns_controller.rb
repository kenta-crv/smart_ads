class CampaignsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_campaign, only: [:show, :edit, :update, :destroy, :send_campaign, :confirm_payment]

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

  def confirm_payment
    @campaign = current_user.campaigns.find(params[:id])
    recipient_count = current_user.push_subscriptions.where(status: "active").count
    @delivery_cost = skip_delivery_payment? ? 0 : recipient_count * Subscription::DELIVERY_COST
    
    unless current_user.can_send_campaign?(recipient_count)
      redirect_to user_campaigns_path(current_user), 
                  alert: "配信数の上限に達しています。プランをアップグレードしてください。"
      return
    end

    subscription = current_user.current_subscription
    unless subscription&.can_send_delivery?(recipient_count)
      redirect_to user_campaigns_path(current_user),
                  alert: "配信数の上限に達しています。プランをアップグレードしてください。"
      return
    end
  end

  def send_campaign
    recipient_count = current_user.push_subscriptions.where(status: "active").count
    
    delivery_cost = skip_delivery_payment? ? 0 : recipient_count * Subscription::DELIVERY_COST
    
    subscription = current_user.current_subscription
    unless subscription&.can_send_delivery?(recipient_count)
      redirect_to user_campaigns_path(current_user),
                  alert: "配信数の上限に達しています。プランをアップグレードしてください。"
      return
    end

    if delivery_cost > 0
      redirect_to confirm_payment_user_campaign_path(current_user, @campaign)
      return
    end
    result = send_campaign_directly(@campaign)
    redirect_to user_campaigns_path(@campaign.user),
                notice: "キャンペーンを送信しました！（成功: #{result[:sent]}件、失敗: #{result[:failed]}件）"
  rescue => e
    Rails.logger.error "Campaign send failed (campaign_id=#{@campaign.id}): #{e.class} - #{e.message}"
    redirect_to user_campaign_path(@campaign),
                alert: "キャンペーンの送信に失敗しました: #{e.message}"
  end

  private

  def send_campaign_directly(campaign)
    ::PushNotificationSender.deliver(campaign)
  end

  private

  def skip_delivery_payment?
    Rails.env.development? || ENV["SKIP_DELIVERY_PAYMENT"] == "true"
  end

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
