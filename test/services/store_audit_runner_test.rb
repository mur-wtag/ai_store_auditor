# frozen_string_literal: true

require "test_helper"

class StoreAuditRunnerTest < ActiveSupport::TestCase
  test "persists a completed audit and updates the shop score" do
    audit = shops(:other_shop).audits.create!(source: "manual")
    provider = Struct.new(:snapshot) { def call = snapshot }.new(healthy_snapshot)

    result = StoreAuditRunner.new(audit, snapshot_provider: provider).call

    assert_equal "completed", result.status
    assert_equal 100, result.overall_score
    assert_equal 3, result.resources_scanned_count
    assert_equal 100, audit.shop.reload.current_score
    assert_not_nil audit.shop.last_audited_at
  end

  test "marks an audit failed when its snapshot provider raises" do
    audit = shops(:other_shop).audits.create!(source: "manual")
    provider = Object.new
    def provider.call = raise("snapshot failure")

    assert_raises(RuntimeError) { StoreAuditRunner.new(audit, snapshot_provider: provider).call }
    assert_equal "failed", audit.reload.status
    assert_includes audit.error_message, "snapshot failure"
  end

  private

  def healthy_snapshot
    {
      "homepage" => {
        "available" => true,
        "title" => "Useful store title",
        "meta_description" => "A specific description for this useful store.",
        "h1_count" => 1,
        "h1_text" => [ "Useful products for thoughtful people" ],
        "image_count" => 1,
        "images_with_alt_count" => 1,
        "has_mobile_viewport" => true,
        "has_cta" => true,
        "has_trust_signals" => true,
        "link_count" => 12
      },
      "products" => [
        {
          "id" => "gid://shopify/Product/2",
          "title" => "Complete Product",
          "handle" => "complete-product",
          "description" => ([ "helpful" ] * 130).join(" "),
          "seo" => { "title" => "Complete Product | Example", "description" => "A useful search description." },
          "media" => {
            "nodes" => [
              { "mediaContentType" => "IMAGE", "alt" => "Front view" },
              { "mediaContentType" => "IMAGE", "alt" => "Side view" },
              { "mediaContentType" => "VIDEO", "alt" => nil }
            ]
          }
        }
      ],
      "collections" => [
        {
          "id" => "gid://shopify/Collection/2",
          "title" => "Complete Collection",
          "handle" => "complete-collection",
          "description" => "A helpful collection introduction.",
          "image" => { "url" => "https://cdn.example/image.jpg" }
        }
      ],
      "menus" => [ { "title" => "Main menu", "items" => [ { "title" => "Contact", "items" => [] } ] } ]
    }
  end
end
