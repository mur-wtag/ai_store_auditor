# frozen_string_literal: true

class MerchantEmailNotifications
  class << self
    def welcome(shop)
      deliver_once(shop, :welcome_email_sent_at) { MerchantMailer.welcome(shop.id).deliver_later }
    end

    def audit_completed(audit)
      deliver_once(audit, :completion_email_sent_at) { MerchantMailer.audit_completed(audit.id).deliver_later }
    end

    def audit_failed(audit)
      deliver_once(audit, :failure_email_sent_at) { MerchantMailer.audit_failed(audit.id).deliver_later }
    end

    def billing_changed(shop, previous_status:, previous_plan_key:)
      return false unless emailable?(shop)
      return false if previous_status == shop.billing_status && previous_plan_key == shop.billing_plan_key

      previous_plan_name = BillingPlan.find(previous_plan_key)&.name
      MerchantMailer.billing_changed(
        shop.id,
        previous_plan_name: previous_plan_name,
        previous_status: previous_status
      ).deliver_later
      true
    end

    def audit_limit_reached(shop)
      return false unless emailable?(shop)

      period_start = shop.usage_period_start
      return false if period_start && shop.audit_limit_email_period_started_at == period_start

      MerchantMailer.audit_limit_reached(shop.id).deliver_later
      shop.update_column(:audit_limit_email_period_started_at, period_start || Time.current)
      true
    end

    def trial_ending(shop)
      deliver_once(shop, :trial_ending_email_sent_at) { MerchantMailer.trial_ending(shop.id).deliver_later }
    end

    def app_uninstalled(shop)
      return false unless emailable?(shop)

      MerchantMailer.app_uninstalled(
        shopify_domain: shop.shopify_domain,
        shop_name: shop.shop_name,
        shop_email: shop.shop_email
      ).deliver_later
      true
    end

    def emailable?(record)
      shop = record.is_a?(Shop) ? record : record&.shop
      shop&.shop_email.present?
    end

    private

    def deliver_once(record, timestamp_column)
      return false unless emailable?(record)
      return false if record.public_send(timestamp_column).present?

      yield
      record.update_column(timestamp_column, Time.current)
      true
    end
  end
end
