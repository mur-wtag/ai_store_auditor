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
  end
end
