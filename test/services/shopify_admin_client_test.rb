# frozen_string_literal: true

require "test_helper"

class ShopifyAdminClientTest < ActiveSupport::TestCase
  test "cancels an app subscription without requesting a prorated refund" do
    client = ShopifyAdminClient.new("example.myshopify.com", access_token: "test-token")
    captured = nil
    client.define_singleton_method(:graphql) do |query, variables|
      captured = { query: query, variables: variables }
      {
        "data" => {
          "appSubscriptionCancel" => {
            "userErrors" => [],
            "appSubscription" => { "id" => variables[:id], "status" => "CANCELLED" }
          }
        }
      }
    end

    payload = client.cancel_app_subscription(id: "gid://shopify/AppSubscription/123", prorate: false)

    assert_includes captured[:query], "appSubscriptionCancel"
    assert_equal({ id: "gid://shopify/AppSubscription/123", prorate: false }, captured[:variables])
    assert_equal "CANCELLED", payload.dig("appSubscription", "status")
  end
end
