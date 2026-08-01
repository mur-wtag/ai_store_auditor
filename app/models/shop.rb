# frozen_string_literal: true

class Shop < ApplicationRecord
  include ShopifyApp::ShopSessionStorage

  class BillingRequired < StandardError; end
  class AuditLimitReached < StandardError; end
  class AuditInProgress < StandardError; end

  BILLING_STATUSES = %w[none active frozen cancelled declined expired unrecognized].freeze

  has_many :audits, dependent: :destroy
  has_many :findings, through: :audits

  normalizes :shopify_domain, with: ->(domain) { domain.to_s.strip.downcase }

  validates :shopify_domain,
    presence: true,
    uniqueness: true,
    format: { with: /\A[a-z0-9][a-z0-9-]*\.myshopify\.com\z/ }
  validates :monthly_revenue_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :billing_status, inclusion: { in: BILLING_STATUSES }
  validates :billing_plan_key, inclusion: { in: BillingPlan::PLANS.keys }, allow_nil: true

  def api_version
    ShopifyApp.configuration.api_version
  end

  def latest_audit
    audits.order(created_at: :desc).first
  end

  def audit_in_progress?
    audits.where(status: %w[queued running]).exists?
  end

  def billing_plan
    BillingPlan.find(billing_plan_key)
  end

  def billing_active?
    billing_status == "active" && billing_plan.present?
  end

  def billing_trial?
    billing_active? && billing_trial_ends_at&.future?
  end

  def billing_usage_period_start(at: Time.current)
    start_at = billing_usage_period_started_at || billing_subscription_created_at
    return unless start_at

    periods = [ ((at - start_at) / 30.days).floor, 0 ].max
    start_at + periods * 30.days
  end

  def audits_used(at: Time.current)
    period_start = billing_usage_period_start(at: at)
    return 0 unless period_start

    audits.where.not(source: "install").where.not(status: "failed").where(created_at: period_start..at).count
  end

  def audits_remaining(at: Time.current)
    return 0 unless billing_active?

    [ billing_plan.audit_limit - audits_used(at: at), 0 ].max
  end

  def free_preview_available?
    !audits.where.not(status: "failed").exists?
  end

  def can_start_audit?
    !audit_in_progress? && (free_preview_available? || (billing_active? && audits_remaining.positive?))
  end

  def reserve_audit!(source: "manual")
    with_lock do
      raise AuditInProgress, "A store audit is already running." if audit_in_progress?

      return audits.create!(source: "install") if free_preview_available?
      raise BillingRequired, "Choose a plan to run another store audit." unless billing_active?

      period_start = billing_usage_period_start
      if period_start && billing_usage_period_started_at != period_start
        update!(billing_usage_period_started_at: period_start)
      end

      raise AuditLimitReached, "Your #{billing_plan.name} plan audit allowance has been used for this 30-day period." if audits_remaining.zero?

      audits.create!(source: source)
    end
  end

  def admin_client
    ShopifyAdminClient.new(shopify_domain, access_token: shopify_token)
  end
end
