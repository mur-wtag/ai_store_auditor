# frozen_string_literal: true

class MerchantMailer < ApplicationMailer
  helper_method :app_name, :support_email

  def welcome(shop_id)
    @shop = Shop.find(shop_id)
    @dashboard_url = dashboard_url_for(@shop)

    mail(to: @shop.shop_email, subject: "Welcome to Sofenx AI Store Auditor")
  end

  def audit_completed(audit_id)
    @audit = Audit.find(audit_id)
    @shop = @audit.shop
    @findings = @audit.top_findings(3)
    @dashboard_url = dashboard_url_for(@shop)

    mail(to: @shop.shop_email, subject: "Your store audit is ready: #{@audit.overall_score}/100")
  end

  def audit_failed(audit_id)
    @audit = Audit.find(audit_id)
    @shop = @audit.shop
    @dashboard_url = dashboard_url_for(@shop)

    mail(to: @shop.shop_email, subject: "Your store audit needs another try")
  end

  def billing_changed(shop_id, previous_plan_name:, previous_status:)
    @shop = Shop.find(shop_id)
    @previous_plan_name = previous_plan_name
    @previous_status = previous_status
    @plans_url = plans_url_for(@shop)

    subject = if @shop.billing_active?
      previous_plan_name.present? ? "Your plan changed to #{@shop.billing_plan.name}" : "Your #{@shop.billing_plan.name} plan is active"
    else
      "Your paid AI Store Auditor plan has ended"
    end

    mail(to: @shop.shop_email, subject: subject)
  end

  def audit_limit_reached(shop_id)
    @shop = Shop.find(shop_id)
    @plans_url = plans_url_for(@shop)

    mail(to: @shop.shop_email, subject: "Your #{@shop.entitlement_plan.name} audit allowance is used")
  end

  def trial_ending(shop_id)
    @shop = Shop.find(shop_id)
    @plans_url = plans_url_for(@shop)

    mail(to: @shop.shop_email, subject: "Your #{@shop.billing_plan.name} trial ends soon")
  end

  def app_uninstalled(shop_attributes)
    details = shop_attributes.with_indifferent_access
    @shop_name = details[:shop_name].presence || details.fetch(:shopify_domain)
    @shop_domain = details.fetch(:shopify_domain)

    mail(to: details.fetch(:shop_email), subject: "Sofenx AI Store Auditor was uninstalled")
  end

  private

  def app_name
    "Sofenx AI Store Auditor"
  end

  def support_email
    ENV.fetch("SUPPORT_EMAIL", "support@sofenx.com")
  end

  def dashboard_url_for(shop)
    shopify_admin_app_url(shop)
  end

  def plans_url_for(shop)
    shopify_admin_app_url(shop, path: "/plans")
  end

  def shopify_admin_app_url(shop, path: "")
    store_handle = shop.shopify_domain.delete_suffix(".myshopify.com")
    app_handle = ENV.fetch("SHOPIFY_APP_HANDLE", "sofenx-ai-store-auditor")
    "https://admin.shopify.com/store/#{store_handle}/apps/#{app_handle}#{path}"
  end
end
