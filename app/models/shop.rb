# frozen_string_literal: true

class Shop < ApplicationRecord
  include ShopifyApp::ShopSessionStorage

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

  def billing_trial?(at: Time.current)
    billing_active? && billing_trial_ends_at&.after?(at)
  end

  def entitlement_plan
    billing_active? ? billing_plan : BillingPlan.free
  end

  def findings_limit
    billing_active? ? 10 : 5
  end

  def billing_usage_period_start(at: Time.current)
    start_at = billing_usage_period_started_at || billing_subscription_created_at
    return unless start_at

    periods = [ ((at - start_at) / 30.days).floor, 0 ].max
    start_at + periods * 30.days
  end

  def free_usage_period_start(at: Time.current)
    start_at = audits.where.not(status: "failed").minimum(:created_at) || created_at
    periods = [ ((at - start_at) / 30.days).floor, 0 ].max
    start_at + periods * 30.days
  end

  def usage_period_start(at: Time.current)
    billing_active? ? billing_usage_period_start(at: at) : free_usage_period_start(at: at)
  end

  def usage_period_ends_at(at: Time.current)
    usage_period_start(at: at) + 30.days
  end

  def audits_used(at: Time.current)
    if billing_trial?(at: at)
      return audits.where.not(status: "failed").where(created_at: ..at).count
    end

    period_start = usage_period_start(at: at)
    return 0 unless period_start

    usage_audits = audits.where.not(status: "failed").where(created_at: period_start..at)
    usage_audits = usage_audits.where.not(source: "install") if billing_active?
    usage_audits.count
  end

  def audit_limit(at: Time.current)
    billing_trial?(at: at) ? BillingPlan::TRIAL_AUDIT_LIMIT : entitlement_plan.audit_limit
  end

  def audits_remaining(at: Time.current)
    [ audit_limit(at: at) - audits_used(at: at), 0 ].max
  end

  def free_preview_available?
    !audits.where.not(status: "failed").exists?
  end

  def can_start_audit?
    !audit_in_progress? && audits_remaining.positive?
  end

  def reserve_audit!(source: "manual")
    with_lock do
      raise AuditInProgress, "A store audit is already running." if audit_in_progress?

      period_start = usage_period_start
      if billing_active? && period_start && billing_usage_period_started_at != period_start
        update!(billing_usage_period_started_at: period_start)
      end

      if audits_remaining.zero?
        message = if billing_trial?
          "Your one-audit introductory trial allowance has been used. Paid plan allowances become available after the trial."
        else
          "Your #{entitlement_plan.name} plan audit allowance has been used for this 30-day period."
        end
        raise AuditLimitReached, message
      end

      audits.create!(source: free_preview_available? ? "install" : source)
    end
  end

  def admin_client
    refresh_token_if_expired!
    ShopifyAdminClient.new(shopify_domain, access_token: shopify_token)
  rescue ShopifyApp::RefreshTokenExpiredError, ShopifyAPI::Errors::HttpResponseError => error
    raise ShopifyAdminClient::Error, "Shopify access needs to be renewed: #{error.message}"
  end
end
