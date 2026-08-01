# frozen_string_literal: true

class Shop < ApplicationRecord
  include ShopifyApp::ShopSessionStorage

  has_many :audits, dependent: :destroy
  has_many :findings, through: :audits

  normalizes :shopify_domain, with: ->(domain) { domain.to_s.strip.downcase }

  validates :shopify_domain,
    presence: true,
    uniqueness: true,
    format: { with: /\A[a-z0-9][a-z0-9-]*\.myshopify\.com\z/ }
  validates :monthly_revenue_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def api_version
    ShopifyApp.configuration.api_version
  end

  def latest_audit
    audits.order(created_at: :desc).first
  end

  def audit_in_progress?
    audits.where(status: %w[queued running]).exists?
  end

  def admin_client
    ShopifyAdminClient.new(shopify_domain, access_token: shopify_token)
  end
end
