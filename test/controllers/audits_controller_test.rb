# frozen_string_literal: true

require "test_helper"

class AuditsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test "queues a manual audit for the authenticated shop" do
    shop = shops(:other_shop)

    assert_enqueued_with(job: StoreAuditJob) do
      assert_difference -> { shop.audits.count }, 1 do
        post audits_url, params: { shop: shop.shopify_domain }
      end
    end

    audit = shop.audits.order(:created_at).last
    expected_query = { shop: shop.shopify_domain, host: Base64.strict_encode64("#{shop.shopify_domain}/admin"), embedded: "1" }.to_query
    assert_redirected_to "#{audit_path(audit)}?#{expected_query}"
  end

  test "cannot read an audit that belongs to another shop" do
    get audit_url(audits(:completed_audit)), params: { shop: shops(:other_shop).shopify_domain }

    assert_response :not_found
  end
end
