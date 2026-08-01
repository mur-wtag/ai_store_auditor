# frozen_string_literal: true

require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  test "renders plan prices, allowances, and agency boundary" do
    billing = Object.new
    billing.define_singleton_method(:reconcile!) { true }

    with_shopify_billing(billing) do
      get plans_url, params: { shop: shops(:regular_shop).shopify_domain }
    end

    assert_response :success
    assert_select "article.plan-card", count: 4
    assert_select "article.plan-card", text: /\$19/
    assert_select "article.plan-card", text: /15 full-store audits every 30 days/
    assert_select "article.plan-card-agency", text: /Coming after multi-store launch/
  end
end
