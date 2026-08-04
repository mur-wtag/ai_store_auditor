# frozen_string_literal: true

require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  test "renders lower launch prices and recurring free plan without agency" do
    billing = Object.new
    billing.define_singleton_method(:reconcile!) { true }

    with_shopify_billing(billing) do
      get plans_url, params: { shop: shops(:regular_shop).shopify_domain }
    end

    assert_response :success
    assert_select "article.plan-card", count: 4
    assert_select "article.plan-card", text: /\$0/
    assert_select "article.plan-card", text: /\$9\.99/
    assert_select "article.plan-card", text: /\$19\.99/
    assert_select "article.plan-card", text: /\$39\.99/
    assert_select "article.plan-card", text: /1 full-store audit every 30 days/
    assert_select "article.plan-card", text: /15 full-store audits every 30 days/
    assert_select ".plan-card-agency", count: 0
    assert_select "button", text: "Downgrade to Free"
    assert_select "form input[name=_method][value=delete]"
    assert_select "form[data-turbo=false][target=_top]", count: 2
  end
end
