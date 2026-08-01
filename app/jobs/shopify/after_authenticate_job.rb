# frozen_string_literal: true

module Shopify
  class AfterAuthenticateJob < ApplicationJob
    queue_as :default

    def perform(shop_domain:)
      shop = Shop.find_by!(shopify_domain: shop_domain)
      ShopifyShopProfileSync.call(shop)
      return if shop.audit_in_progress? || shop.audits.completed.exists?

      audit = shop.audits.create!(source: "install")
      StoreAuditJob.perform_later(audit.id)
    end
  end
end
