class User::SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_subscription, only: [:show, :update, :cancel]

  def show
    @subscription = current_user.current_subscription
    @payments = current_user.payments.order(created_at: :desc).limit(10)
  end

  def update
    new_plan_type = params[:plan_type]
    
    unless Subscription::PLAN_PRICES.key?(new_plan_type.to_sym)
      redirect_to user_subscription_path(current_user), alert: "無効なプランです。"
      return
    end

    if new_plan_type != current_user.subscription_plan
      redirect_to checkout_confirmation_path(plan_type: new_plan_type)
    else
      redirect_to user_subscription_path(current_user), notice: "同じプランです。"
    end
  end

  def cancel
    @subscription = current_user.current_subscription
    
    if @subscription&.update(status: :cancelled)
      current_user.update(subscription_status: "cancelled")
      redirect_to user_subscription_path, notice: "サブスクリプションをキャンセルしました。"
    else
      redirect_to user_subscription_path, alert: "キャンセルに失敗しました。"
    end
  end

  private

  def set_subscription
    @subscription = current_user.current_subscription
  end
end

