# frozen_string_literal: true

module ShopifyWebhooks
  class CustomersRedactJob < ApplicationWebhookJob
    def perform(topic:, shop_domain:, webhook:, webhook_id:, api_version:)
      # This MVP never requests or stores customer or order data.
      Rails.logger.info("Customer redact #{webhook_id} for #{shop_domain}: no customer data stored")
    end
  end
end
