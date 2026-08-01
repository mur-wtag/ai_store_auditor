# frozen_string_literal: true

class ShopifyBilling
  class Error < StandardError; end

  def initialize(shop, client: shop.admin_client)
    @shop = shop
    @client = client
  end

  def create_subscription!(plan:, return_url:)
    test_charge = client.partner_development_shop?
    shop.update!(partner_development_shop: test_charge) if shop.partner_development_shop? != test_charge

    payload = client.create_app_subscription(
      name: plan.subscription_name,
      amount: plan.price,
      return_url: return_url,
      trial_days: shop.billing_first_activated_at? ? 0 : BillingPlan::TRIAL_DAYS,
      test: test_charge
    )

    errors = Array(payload["userErrors"])
    raise Error, errors.map { |error| error["message"] }.join(", ") if errors.any?

    confirmation_url = payload["confirmationUrl"].presence
    subscription_id = payload.dig("appSubscription", "id").presence
    raise Error, "Shopify did not return a subscription confirmation URL" unless confirmation_url && subscription_id

    shop.update!(
      billing_pending_plan_key: plan.key,
      billing_pending_subscription_id: subscription_id
    )

    confirmation_url
  rescue ShopifyAdminClient::Error => error
    raise Error, error.message
  end

  def reconcile!
    subscriptions = client.active_app_subscriptions
    subscription = subscriptions.find { |candidate| BillingPlan.from_subscription_name(candidate["name"]) }

    if subscription
      activate!(subscription)
    elsif subscriptions.any?
      mark_unrecognized!(subscriptions.first)
    else
      clear_subscription!
    end

    shop.reload
  rescue ShopifyAdminClient::Error => error
    raise Error, error.message
  end

  private

  attr_reader :shop, :client

  def activate!(subscription)
    plan = BillingPlan.from_subscription_name(subscription.fetch("name"))
    created_at = Time.zone.parse(subscription.fetch("createdAt"))
    current_period_end = parse_time(subscription["currentPeriodEnd"])
    new_subscription = shop.shopify_app_subscription_id != subscription.fetch("id")
    usage_period_started_at = new_subscription ? created_at : shop.billing_usage_period_started_at.presence || created_at
    trial_days = subscription.fetch("trialDays", 0).to_i

    shop.update!(
      billing_plan_key: plan.key,
      billing_status: subscription.fetch("status").downcase,
      shopify_app_subscription_id: subscription.fetch("id"),
      billing_test: subscription.fetch("test"),
      billing_subscription_created_at: created_at,
      billing_current_period_end: current_period_end,
      billing_trial_ends_at: trial_days.positive? ? created_at + trial_days.days : nil,
      billing_first_activated_at: shop.billing_first_activated_at || Time.current,
      billing_usage_period_started_at: usage_period_started_at,
      billing_synced_at: Time.current,
      billing_pending_plan_key: nil,
      billing_pending_subscription_id: nil
    )
  end

  def mark_unrecognized!(subscription)
    shop.update!(
      billing_plan_key: nil,
      billing_status: "unrecognized",
      shopify_app_subscription_id: subscription["id"],
      billing_synced_at: Time.current,
      billing_pending_plan_key: nil,
      billing_pending_subscription_id: nil
    )
  end

  def clear_subscription!
    shop.update!(
      billing_plan_key: nil,
      billing_status: "none",
      shopify_app_subscription_id: nil,
      billing_test: false,
      billing_subscription_created_at: nil,
      billing_current_period_end: nil,
      billing_trial_ends_at: nil,
      billing_usage_period_started_at: nil,
      billing_synced_at: Time.current,
      billing_pending_plan_key: nil,
      billing_pending_subscription_id: nil
    )
  end

  def parse_time(value)
    Time.zone.parse(value) if value.present?
  end
end
