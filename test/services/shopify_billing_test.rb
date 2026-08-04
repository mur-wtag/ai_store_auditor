# frozen_string_literal: true

require "test_helper"

class ShopifyBillingTest < ActiveSupport::TestCase
  FakeClient = Struct.new(
    :subscriptions,
    :create_payload,
    :create_arguments,
    :cancel_payload,
    :cancel_arguments,
    :development_shop,
    keyword_init: true
  ) do
    def active_app_subscriptions
      subscriptions
    end

    def create_app_subscription(**arguments)
      self.create_arguments = arguments
      create_payload
    end

    def cancel_app_subscription(**arguments)
      self.cancel_arguments = arguments
      cancel_payload
    end

    def partner_development_shop?
      development_shop == true
    end
  end

  test "creates a test subscription with a first-time trial for a development shop" do
    shop = shops(:other_shop)
    shop.update!(partner_development_shop: true, billing_first_activated_at: nil)
    client = FakeClient.new(development_shop: true, create_payload: {
      "userErrors" => [],
      "confirmationUrl" => "https://example.myshopify.com/admin/charges/confirm",
      "appSubscription" => { "id" => "gid://shopify/AppSubscription/2001" }
    })

    url = ShopifyBilling.new(shop, client: client).create_subscription!(
      plan: BillingPlan.find!("growth"),
      return_url: "https://ssa.sofenx.com/billing_subscription/callback"
    )

    assert_equal "https://example.myshopify.com/admin/charges/confirm", url
    assert_equal 7, client.create_arguments[:trial_days]
    assert client.create_arguments[:test]
    assert_equal "growth", shop.reload.billing_pending_plan_key
  end

  test "does not grant another trial when switching plans" do
    shop = shops(:other_shop)
    client = FakeClient.new(create_payload: {
      "userErrors" => [],
      "confirmationUrl" => "https://example.myshopify.com/admin/charges/confirm",
      "appSubscription" => { "id" => "gid://shopify/AppSubscription/2002" }
    })

    ShopifyBilling.new(shop, client: client).create_subscription!(plan: BillingPlan.find!("pro"), return_url: "https://ssa.sofenx.com/callback")

    assert_equal 0, client.create_arguments[:trial_days]
  end

  test "reconciles a known active subscription" do
    shop = shops(:other_shop)
    client = FakeClient.new(subscriptions: [ {
      "id" => "gid://shopify/AppSubscription/3001",
      "name" => BillingPlan.find!("growth").subscription_name,
      "status" => "ACTIVE",
      "test" => true,
      "trialDays" => 7,
      "createdAt" => 2.days.ago.iso8601,
      "currentPeriodEnd" => 35.days.from_now.iso8601
    } ])

    ShopifyBilling.new(shop, client: client).reconcile!

    shop.reload
    assert_equal "growth", shop.billing_plan_key
    assert_equal "active", shop.billing_status
    assert shop.billing_test?
    assert shop.billing_trial_ends_at.future?
    assert_nil shop.billing_pending_plan_key
  end

  test "clears cached access when Shopify has no active subscription" do
    shop = shops(:other_shop)

    ShopifyBilling.new(shop, client: FakeClient.new(subscriptions: [])).reconcile!

    assert_equal "none", shop.reload.billing_status
    assert_nil shop.billing_plan_key
    assert_nil shop.shopify_app_subscription_id
  end

  test "surfaces Shopify user errors" do
    client = FakeClient.new(create_payload: { "userErrors" => [ { "message" => "Billing unavailable" } ] })

    error = assert_raises(ShopifyBilling::Error) do
      ShopifyBilling.new(shops(:other_shop), client: client).create_subscription!(plan: BillingPlan.find!("starter"), return_url: "https://ssa.sofenx.com/callback")
    end

    assert_equal "Billing unavailable", error.message
  end

  test "cancels an active subscription and moves the shop to free" do
    shop = shops(:regular_shop)
    subscription_id = shop.shopify_app_subscription_id
    client = FakeClient.new(cancel_payload: {
      "userErrors" => [],
      "appSubscription" => { "id" => subscription_id, "status" => "CANCELLED" }
    })

    ShopifyBilling.new(shop, client: client).cancel_subscription!

    assert_equal({ id: subscription_id, prorate: false }, client.cancel_arguments)
    shop.reload
    assert_equal "none", shop.billing_status
    assert_nil shop.billing_plan_key
    assert_nil shop.shopify_app_subscription_id
  end

  test "does not clear paid access when Shopify rejects cancellation" do
    shop = shops(:regular_shop)
    client = FakeClient.new(cancel_payload: {
      "userErrors" => [ { "message" => "Subscription cannot be cancelled" } ],
      "appSubscription" => nil
    })

    error = assert_raises(ShopifyBilling::Error) do
      ShopifyBilling.new(shop, client: client).cancel_subscription!
    end

    assert_equal "Subscription cannot be cancelled", error.message
    assert shop.reload.billing_active?
  end

  test "rejects cancellation when the shop is already free" do
    shop = shops(:other_shop)
    shop.update!(billing_status: "none", billing_plan_key: nil, shopify_app_subscription_id: nil)

    error = assert_raises(ShopifyBilling::Error) do
      ShopifyBilling.new(shop, client: FakeClient.new).cancel_subscription!
    end

    assert_equal "There is no active paid subscription to cancel", error.message
  end
end
