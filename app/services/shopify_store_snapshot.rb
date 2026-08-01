# frozen_string_literal: true

class ShopifyStoreSnapshot
  attr_reader :shop

  def initialize(shop)
    @shop = shop
  end

  def call
    data = shop.admin_client.audit_snapshot
    shop_data = data.fetch("shop")
    homepage = homepage_snapshot(shop_data.dig("primaryDomain", "url"))

    shop.update!(
      shop_name: shop_data["name"],
      shop_email: shop_data["email"],
      currency_code: shop_data["currencyCode"],
      primary_domain_url: shop_data.dig("primaryDomain", "url")
    )

    {
      "shop" => shop_data,
      "products" => data.dig("products", "nodes") || [],
      "collections" => data.dig("collections", "nodes") || [],
      "menus" => data.dig("menus", "nodes") || [],
      "homepage" => homepage
    }
  end

  private

  def homepage_snapshot(url)
    StorefrontHomepageFetcher.new(url).call.merge("available" => true)
  rescue StorefrontHomepageFetcher::Error => error
    { "available" => false, "error" => error.message }
  end
end
