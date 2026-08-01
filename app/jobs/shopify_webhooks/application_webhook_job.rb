# frozen_string_literal: true

module ShopifyWebhooks
  class ApplicationWebhookJob < ApplicationJob
    include ShopifyAPI::Webhooks::WebhookHandler

    def handle(data:)
      self.class.perform_later(
        topic: data.topic,
        shop_domain: data.shop,
        webhook: data.body,
        webhook_id: data.webhook_id,
        api_version: data.api_version
      )
    end

    class << self
      def handle(topic:, shop:, body:, webhook_id:, api_version:)
        perform_later(topic: topic, shop_domain: shop, webhook: body, webhook_id: webhook_id, api_version: api_version)
      end
    end
  end
end
