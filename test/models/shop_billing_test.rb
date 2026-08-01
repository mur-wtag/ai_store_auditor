# frozen_string_literal: true

require "test_helper"

class ShopBillingTest < ActiveSupport::TestCase
  test "allows one free preview without a subscription" do
    shop = Shop.create!(shopify_domain: "preview-shop.myshopify.com", shopify_token: "token")

    audit = shop.reserve_audit!

    assert_equal "install", audit.source
    assert_raises(Shop::AuditInProgress) { shop.reserve_audit! }
  end

  test "requires a subscription after the free preview" do
    shop = shops(:regular_shop)
    shop.update!(billing_plan_key: nil, billing_status: "none")

    assert_raises(Shop::BillingRequired) { shop.reserve_audit! }
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
end
