# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "updates the revenue baseline in cents" do
    shop = shops(:regular_shop)

    patch settings_url, params: { shop: shop.shopify_domain, settings: { monthly_revenue: "24500.75" } }

    expected_query = { shop: shop.shopify_domain, host: Base64.strict_encode64("#{shop.shopify_domain}/admin"), embedded: "1" }.to_query
    assert_redirected_to "#{root_path}?#{expected_query}"
    assert_equal 2_450_075, shop.reload.monthly_revenue_cents
  end

  test "rejects an invalid revenue baseline" do
    patch settings_url, params: { shop: shops(:regular_shop).shopify_domain, settings: { monthly_revenue: "unknown" } }

    assert_response :unprocessable_entity
  end
end
