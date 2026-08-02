# frozen_string_literal: true

require "test_helper"

class ShopifyWebhooks::AppUninstalledJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "queues confirmation with captured attributes before deleting shop data" do
    shop = shops(:regular_shop)

    assert_enqueued_emails 1 do
      ShopifyWebhooks::AppUninstalledJob.perform_now(
        topic: "app/uninstalled",
        shop_domain: shop.shopify_domain,
        webhook: {},
        webhook_id: "webhook-1",
        api_version: "2026-07"
      )
    end

    assert_nil Shop.find_by(id: shop.id)
  end
end
