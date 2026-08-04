# frozen_string_literal: true

require "test_helper"

class BillingSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  test "redirects to Shopify to approve a new plan" do
    shop = shops(:other_shop)
    billing = Object.new
    billing.define_singleton_method(:create_subscription!) do |plan:, return_url:|
      raise "wrong plan" unless plan.key == "growth"
      return_uri = URI.parse(return_url)
      return_query = Rack::Utils.parse_nested_query(return_uri.query)
      raise "wrong callback path" unless return_uri.path == "/billing_subscription/callback"
      raise "wrong callback host" unless return_uri.host == "www.example.com"
      raise "missing embedded host" unless return_query["host"] == Base64.strict_encode64("#{shop.shopify_domain}/admin")

      "https://other-shop.myshopify.com/admin/charges/confirm"
    end

    with_shopify_billing(billing) do
      post billing_subscription_url, params: { shop: shop.shopify_domain, plan: "growth" }
    end

    assert_response :see_other
    assert_includes response.location, redirect_billing_subscription_path

    follow_redirect!

    assert_response :success
    assert_select "#redirection-target[data-target]", count: 1
    assert_includes response.body, "https://other-shop.myshopify.com/admin/charges/confirm"
  end

  test "rejects an invalid billing redirect token" do
    shop = shops(:other_shop)

    get redirect_billing_subscription_url, params: { shop: shop.shopify_domain, token: "invalid" }

    assert_redirected_to navigation_url(plans_path, shop)
    assert_equal "The Shopify billing approval link expired. Please choose the plan again.", flash[:alert]
  end

  test "does not recreate the current plan" do
    shop = shops(:regular_shop)

    post billing_subscription_url, params: { shop: shop.shopify_domain, plan: "starter" }

    assert_redirected_to navigation_url(plans_path, shop)
  end

  test "does not create a Shopify charge for the free plan" do
    shop = shops(:other_shop)

    post billing_subscription_url, params: { shop: shop.shopify_domain, plan: "free" }

    assert_redirected_to navigation_url(plans_path, shop)
    assert_equal "Choose a valid plan.", flash[:alert]
  end

  test "cancels a paid subscription and activates free" do
    shop = shops(:regular_shop)
    billing = Object.new
    billing.define_singleton_method(:cancel_subscription!) do
      shop.update!(billing_plan_key: nil, billing_status: "none", shopify_app_subscription_id: nil)
    end

    with_shopify_billing(billing) do
      delete billing_subscription_url, params: { shop: shop.shopify_domain }
    end

    assert_redirected_to navigation_url(plans_path, shop)
    assert_equal "Your paid subscription was cancelled. Free is now active.", flash[:notice]
    assert_equal "none", shop.reload.billing_status
  end

  test "does not call Shopify when free is already active" do
    shop = shops(:other_shop)
    shop.update!(billing_plan_key: nil, billing_status: "none", shopify_app_subscription_id: nil)

    delete billing_subscription_url, params: { shop: shop.shopify_domain }

    assert_redirected_to navigation_url(plans_path, shop)
    assert_equal "Free is already active.", flash[:notice]
  end

  test "keeps the paid plan when cancellation fails" do
    shop = shops(:regular_shop)
    billing = Object.new
    billing.define_singleton_method(:cancel_subscription!) do
      raise ShopifyBilling::Error, "Billing unavailable"
    end

    with_shopify_billing(billing) do
      delete billing_subscription_url, params: { shop: shop.shopify_domain }
    end

    assert_redirected_to navigation_url(plans_path, shop)
    assert_equal "Shopify could not cancel the subscription: Billing unavailable", flash[:alert]
    assert shop.reload.billing_active?
  end

  test "callback grants access only after Shopify reports an active subscription" do
    shop = shops(:other_shop)
    shop.update!(billing_plan_key: nil, billing_status: "none", shopify_app_subscription_id: nil)
    billing = Object.new
    billing.define_singleton_method(:reconcile!) do
      shop.update!(billing_plan_key: "pro", billing_status: "active", shopify_app_subscription_id: "gid://shopify/AppSubscription/4001")
    end

    with_shopify_billing(billing) do
      get callback_billing_subscription_url, params: { shop: shop.shopify_domain }
    end

    assert_redirected_to navigation_url(plans_path, shop)
    assert_equal "pro", shop.reload.billing_plan_key
  end

  private

  def navigation_url(path, shop)
    query = {
      shop: shop.shopify_domain,
      host: Base64.strict_encode64("#{shop.shopify_domain}/admin"),
      embedded: "1"
    }.to_query
    "#{path}?#{query}"
  end
end
