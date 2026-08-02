# frozen_string_literal: true

module Shopify
  class AfterAuthenticateJob < ApplicationJob
    queue_as :default

    def perform(shop_domain:)
      shop = Shop.find_by!(shopify_domain: shop_domain)
      ShopifyShopProfileSync.call(shop)
      reconcile_billing(shop)
      MerchantEmailNotifications.welcome(shop.reload)
      return unless shop.free_preview_available?

      audit = shop.reserve_audit!(source: "install")
      StoreAuditJob.perform_later(audit.id)
    rescue Shop::AuditLimitReached, Shop::AuditInProgress
      nil
    end

    private

    def reconcile_billing(shop)
      ShopifyBilling.new(shop).reconcile!
    rescue ShopifyBilling::Error => error
      Rails.logger.warn("Could not reconcile billing for #{shop.shopify_domain}: #{error.message}")
    end
  end
end
