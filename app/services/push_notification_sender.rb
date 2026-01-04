require "json"

class PushNotificationSender
  MissingVapidKeysError = Class.new(StandardError)

  DEFAULT_TIMEOUTS = {
    ssl_timeout: 5,
    open_timeout: 5,
    read_timeout: 5
  }.freeze

  def self.deliver(campaign, logger: Rails.logger)
    new(campaign, logger: logger).deliver
  end

  def initialize(campaign, logger: Rails.logger)
    @campaign = campaign
    @logger = logger
    @vapid_keys = load_vapid_keys
  end

  def deliver
    result = { sent: 0, failed: 0 }
    @campaign.update(status: "sending")

    @campaign.user.push_subscriptions.where(status: "active").find_each do |subscription|
      delivery_state = deliver_to_subscription(subscription)
      result[:sent] += 1 if delivery_state == :sent
      result[:failed] += 1 if delivery_state == :failed
    end

    result
  ensure
    @campaign.update(status: "completed")
  end

  private

  def load_vapid_keys
    public_key = Rails.application.credentials.dig(:vapid, :public_key) || ENV["VAPID_PUBLIC_KEY"]
    private_key = Rails.application.credentials.dig(:vapid, :private_key) || ENV["VAPID_PRIVATE_KEY"]

    if public_key.blank? || private_key.blank?
      raise MissingVapidKeysError, "VAPID keys are not configured"
    end

    { public_key: public_key, private_key: private_key }
  end

  def deliver_to_subscription(subscription)
    payload = {
      title: @campaign.title,
      body: @campaign.body,
      icon: @campaign.icon_url,
      url: @campaign.target_url
    }

    WebPush.payload_send(
      endpoint: subscription.endpoint,
      message: JSON.generate(payload),
      p256dh: subscription.keys["p256dh"],
      auth: subscription.keys["auth"],
      vapid: @vapid_keys,
      **DEFAULT_TIMEOUTS
    )

    CampaignResult.create!(
      campaign: @campaign,
      push_subscription: subscription,
      status: "completed",
      delivered_at: Time.current
    )

    :sent
  rescue => error
    handle_failure(subscription, error)
    :failed
  end

  def handle_failure(subscription, error)
    CampaignResult.create!(
      campaign: @campaign,
      push_subscription: subscription,
      status: "failed",
      error_message: error.message
    )

    if error.respond_to?(:response) && [404, 410].include?(error.response.code.to_i)
      subscription.update(status: "inactive")
    end

    @logger.error("Push delivery failed for subscription #{subscription.id}: #{error.class} - #{error.message}")
  end
end


