class CheckoutController < ApplicationController
  before_action :authenticate_user!

  def confirmation
    @plan_type = params[:plan_type] || current_user.subscription_plan
    @campaign_id = params[:campaign_id]
    @subscription = Subscription.new(plan_type: @plan_type)
    
    if @campaign_id
      @campaign = current_user.campaigns.find(@campaign_id)
      @amount = @campaign.delivery_cost
      @description = "Campaign delivery: #{@campaign.title}"
    else
      @amount = Subscription::PLAN_PRICES[@plan_type.to_sym] || 0
      @description = "#{@plan_type.capitalize} Plan"
    end

    @payjp_public_key = Rails.application.credentials.dig(:payjp, :public_key) || ENV['PAYJP_PUBLIC_KEY']
  end

  def create
    plan_type = params[:plan_type]
    campaign_id = params[:campaign_id]
    payjp_token = params[:payjp_token]

    unless payjp_token.present?
      redirect_to checkout_confirmation_path(plan_type: plan_type, campaign_id: campaign_id), 
                  alert: "カード情報が正しく入力されていません。"
      return
    end

    begin
      if campaign_id.present?
        process_delivery_payment(campaign_id, payjp_token)
      else
        process_subscription_payment(plan_type, payjp_token)
      end
    rescue Payjp::CardError => e
      redirect_to checkout_confirmation_path(plan_type: plan_type, campaign_id: campaign_id),
                  alert: "カード決済に失敗しました: #{e.message}"
    rescue => e
      Rails.logger.error "Payment error: #{e.message}"
      redirect_to checkout_confirmation_path(plan_type: plan_type, campaign_id: campaign_id),
                  alert: "決済処理中にエラーが発生しました。"
    end
  end

  def success
    @payment = Payment.find_by(id: params[:payment_id]) if params[:payment_id]
    @subscription = Subscription.find_by(id: params[:subscription_id]) if params[:subscription_id]
  end

  def cancel
    redirect_to user_dashboard_index_path, notice: "決済がキャンセルされました。"
  end

  private

  def process_delivery_payment(campaign_id, payjp_token)
    campaign = current_user.campaigns.find(campaign_id)
    recipient_count = current_user.push_subscriptions.where(status: "active").count
    amount = recipient_count * Subscription::DELIVERY_COST

    charge = Payjp::Charge.create(
      amount: amount,
      currency: 'jpy',
      card: payjp_token,
      description: "Campaign delivery: #{campaign.title}"
    )

    payment = current_user.payments.create!(
      campaign: campaign,
      amount: amount,
      payjp_charge_id: charge.id,
      status: charge.paid ? 'succeeded' : 'failed',
      description: "Campaign delivery payment for #{recipient_count} recipients"
    )

    if payment.succeeded?
      send_campaign(campaign)
      redirect_to checkout_success_path(payment_id: payment.id), notice: "決済が完了し、キャンペーンを送信しました。"
    else
      redirect_to checkout_confirmation_path(campaign_id: campaign_id),
                  alert: "決済に失敗しました。"
    end
  end

  def process_subscription_payment(plan_type, payjp_token)
    amount = Subscription::PLAN_PRICES[plan_type.to_sym] || 0
    
    customer_id = current_user.payjp_customer_id
    unless customer_id
      customer = Payjp::Customer.create(
        email: current_user.email,
        description: "User #{current_user.id}"
      )
      customer_id = customer.id
      current_user.update(payjp_customer_id: customer_id)
    end

    charge = Payjp::Charge.create(
      amount: amount,
      currency: 'jpy',
      customer: customer_id,
      description: "#{plan_type.capitalize} Plan subscription"
    )

    if charge.paid
      current_user.subscriptions.where(status: :active).update_all(status: :cancelled)
      
      subscription = current_user.subscriptions.create!(
        plan_type: plan_type,
        status: :active,
        payjp_subscription_id: charge.id
      )

      current_user.update!(
        subscription_plan: plan_type,
        subscription_status: "active",
        trial_ends_at: nil
      )

      redirect_to checkout_success_path(subscription_id: subscription.id), 
                  notice: "プランの登録が完了しました。"
    else
      redirect_to checkout_confirmation_path(plan_type: plan_type),
                  alert: "決済に失敗しました。"
    end
  end

  def send_campaign(campaign)
    campaign.update(status: "sending")

    campaign.user.push_subscriptions.where(status: "active").each do |sub|
      CampaignResult.create!(
        campaign: campaign,
        push_subscription: sub,
        status: "completed",
        delivered_at: Time.current
      )
    end

    campaign.update(status: "completed")
  end
end

