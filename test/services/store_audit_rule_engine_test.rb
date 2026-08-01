# frozen_string_literal: true

require "test_helper"

class StoreAuditRuleEngineTest < ActiveSupport::TestCase
  test "builds evidence-backed findings and capped opportunity" do
    result = StoreAuditRuleEngine.new(snapshot: snapshot, monthly_revenue_cents: 2_000_000).call

    assert_operator result[:findings].length, :>=, 6
    assert_includes result[:findings].pluck(:rule_key), "product_description_depth"
    assert_includes result[:findings].pluck(:rule_key), "homepage_meta_description"
    assert_includes 0..100, result[:overall_score]
    assert_operator result[:estimated_monthly_opportunity_cents], :<=, 400_000
    assert result[:findings].all? { |finding| finding[:evidence].is_a?(Hash) }
  end

  test "does not invent a revenue value without a baseline" do
    result = StoreAuditRuleEngine.new(snapshot: snapshot, monthly_revenue_cents: 0).call

    assert_equal 0, result[:estimated_monthly_opportunity_cents]
    assert result[:findings].all? { |finding| finding[:estimated_monthly_revenue_cents].zero? }
  end

  private

  def snapshot
    {
      shop: { name: "Example", currencyCode: "USD" },
      homepage: {
        available: true,
        title: "Example",
        meta_description: "",
        h1_count: 0,
        h1_text: [],
        image_count: 4,
        images_with_alt_count: 1,
        has_mobile_viewport: true,
        has_cta: false,
        has_trust_signals: false,
        link_count: 8
      },
      products: [
        {
          id: "gid://shopify/Product/1",
          title: "Travel Mug",
          handle: "travel-mug",
          description: "Short description",
          seo: { title: nil, description: nil },
          media: { nodes: [ { mediaContentType: "IMAGE", alt: nil } ] }
        }
      ],
      collections: [
        {
          id: "gid://shopify/Collection/1",
          title: "Drinkware",
          handle: "drinkware",
          description: "",
          seo: { title: nil, description: nil },
          image: nil
        }
      ],
      menus: [ { title: "Main menu", items: [ { title: "Shop", items: [] } ] } ]
    }
  end
end
