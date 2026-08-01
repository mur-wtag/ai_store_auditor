# frozen_string_literal: true

class ShopifyShopProfileSync
  def self.call(shop)
    data = shop.admin_client.audit_snapshot(product_limit: 1, collection_limit: 1, menu_limit: 1).fetch("shop")

    shop.update!(
      shop_name: data["name"],
      shop_email: data["email"],
      currency_code: data["currencyCode"],
      primary_domain_url: data.dig("primaryDomain", "url"),
      partner_development_shop: data.dig("plan", "partnerDevelopment")
    )
  end
end
