# frozen_string_literal: true

module ShopifyWebhooks
  class ShopRedactJob < ApplicationWebhookJob
    def perform(topic:, shop_domain:, webhook:, webhook_id:, api_version:)
      Shop.find_by(shopify_domain: shop_domain)&.destroy!
      Rails.logger.info("Completed shop redact #{webhook_id} for #{shop_domain}")
    end
  end
end
