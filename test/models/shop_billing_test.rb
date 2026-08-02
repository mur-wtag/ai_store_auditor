# frozen_string_literal: true

require "test_helper"

class ShopBillingTest < ActiveSupport::TestCase
  test "allows one free audit without a subscription" do
    shop = Shop.create!(shopify_domain: "preview-shop.myshopify.com", shopify_token: "token")

    audit = shop.reserve_audit!
    audit.update!(status: "completed")

    assert_equal "install", audit.source
    assert_equal 0, shop.audits_remaining
    assert_raises(Shop::AuditLimitReached) { shop.reserve_audit! }
  end

  test "applies the free plan after a paid subscription ends" do
    shop = shops(:regular_shop)
    shop.update!(billing_plan_key: nil, billing_status: "none")

    assert_equal "Free", shop.entitlement_plan.name
    assert_equal 0, shop.audits_remaining
    assert_raises(Shop::AuditLimitReached) { shop.reserve_audit! }
  end

  test "renews the free audit allowance every 30 days" do
    shop = Shop.create!(shopify_domain: "returning-free-shop.myshopify.com", shopify_token: "token", created_at: 40.days.ago)
    shop.audits.create!(source: "install", status: "completed", created_at: 35.days.ago)

    assert_equal 1, shop.audits_remaining
    assert_equal "manual", shop.reserve_audit!.source
  end

  test "enforces the plan allowance and ignores failed audits" do
    shop = shops(:other_shop)
    4.times { shop.audits.create!(source: "manual", status: "completed") }

    assert_equal 0, shop.audits_remaining
    assert_raises(Shop::AuditLimitReached) { shop.reserve_audit! }

    shop.audits.order(:created_at).last.update!(status: "failed")
    assert_equal 1, shop.reload.audits_remaining
    assert_equal "manual", shop.reserve_audit!.source
  end

  test "starts a new allowance after each 30 day period" do
    shop = shops(:other_shop)
    shop.update!(billing_usage_period_started_at: 35.days.ago)
    shop.audits.create!(source: "manual", status: "completed", created_at: 32.days.ago)

    assert_equal 0, shop.audits_used
    assert_equal 4, shop.audits_remaining
  end

  test "free plans show five findings while paid plans show ten" do
    shop = shops(:other_shop)
    assert_equal 10, shop.findings_limit

    shop.update!(billing_plan_key: nil, billing_status: "none")
    assert_equal 5, shop.findings_limit
  end

  test "refreshes an expired offline token before building an Admin client" do
    shop = shops(:other_shop)
    refreshed = false
    shop.define_singleton_method(:refresh_token_if_expired!) do
      refreshed = true
      self.shopify_token = "refreshed-token"
    end

    client = shop.admin_client

    assert refreshed
    assert_equal "refreshed-token", client.send(:access_token)
  end

  test "turns an expired refresh token into a safe Admin API error" do
    shop = shops(:other_shop)
    shop.define_singleton_method(:refresh_token_if_expired!) { raise ShopifyApp::RefreshTokenExpiredError, "expired" }

    error = assert_raises(ShopifyAdminClient::Error) { shop.admin_client }

    assert_match(/access needs to be renewed/, error.message)
  end
end
