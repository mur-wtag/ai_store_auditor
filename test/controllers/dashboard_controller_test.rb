# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "renders the current shop audit without exposing another shop" do
    get root_url, params: { shop: shops(:regular_shop).shopify_domain }

    assert_response :success
    assert_select "h1", /Know what is holding growth back/
    assert_select ".score-number", /78/
    assert_select ".finding", count: 1
    assert_select "a[href*='host=']", minimum: 2
    assert_select "body", text: /AI-assisted draft is temporarily unavailable/
    assert_select "body", text: /OPENAI_API_KEY/, count: 0
  end

  test "shows a merchant-safe paid upgrade message on free findings" do
    shop = shops(:regular_shop)
    shop.update!(billing_plan_key: nil, billing_status: "none")

    get root_url, params: { shop: shop.shopify_domain }

    assert_response :success
    assert_select "body", text: /AI-assisted exact copy and implementation steps are included with paid plans/
    assert_select "body", text: /OPENAI_API_KEY/, count: 0
  end
end
