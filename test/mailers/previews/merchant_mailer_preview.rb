# frozen_string_literal: true

class MerchantMailerPreview < ActionMailer::Preview
  def welcome
    MerchantMailer.welcome(shop.id)
  end

  def audit_completed
    MerchantMailer.audit_completed(audit.id)
  end

  def audit_failed
    MerchantMailer.audit_failed(audit.id)
  end

  def billing_changed
    MerchantMailer.billing_changed(shop.id, previous_plan_name: "Free", previous_status: "none")
  end

  def audit_limit_reached
    MerchantMailer.audit_limit_reached(shop.id)
  end

  def trial_ending
    MerchantMailer.trial_ending(shop.id)
  end

  def app_uninstalled
    MerchantMailer.app_uninstalled(
      shopify_domain: shop.shopify_domain,
      shop_name: shop.shop_name,
      shop_email: shop.shop_email
    )
  end

  private

  def shop
    Shop.where.not(shop_email: nil).first || raise("Create an emailable shop to preview merchant emails")
  end

  def audit
    shop.audits.completed.order(created_at: :desc).first || raise("Complete an audit to preview audit email")
  end
end
