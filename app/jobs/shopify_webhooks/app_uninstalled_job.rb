# frozen_string_literal: true

module ShopifyWebhooks
  class AppUninstalledJob < ApplicationWebhookJob
    def perform(topic:, shop_domain:, webhook:, webhook_id:, api_version:)
      shop = Shop.find_by(shopify_domain: shop_domain)
      MerchantEmailNotifications.app_uninstalled(shop) if shop
      shop&.destroy!
      Rails.logger.info("Deleted app data after uninstall webhook #{webhook_id} for #{shop_domain}")
    end
  end
end
