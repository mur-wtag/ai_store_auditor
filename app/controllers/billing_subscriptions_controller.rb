# frozen_string_literal: true

class BillingSubscriptionsController < AuthenticatedController
  def create
    plan = BillingPlan.find!(params[:plan])
    if current_shop.billing_active? && current_shop.billing_plan_key == plan.key
      redirect_to with_shopify_navigation_params(plans_path), notice: "#{plan.name} is already active."
      return
    end

    return_url = callback_billing_subscription_url(**shopify_navigation_params)
    confirmation_url = ShopifyBilling.new(current_shop).create_subscription!(plan: plan, return_url: return_url)

    redirect_to confirmation_url, allow_other_host: true, status: :see_other
  rescue ArgumentError
    redirect_to with_shopify_navigation_params(plans_path), alert: "Choose a valid plan."
  rescue ShopifyBilling::Error => error
    redirect_to with_shopify_navigation_params(plans_path), alert: "Shopify could not start billing: #{error.message}"
  end

  def callback
    ShopifyBilling.new(current_shop).reconcile!

    if current_shop.billing_active?
      redirect_to with_shopify_navigation_params(plans_path), notice: "#{current_shop.billing_plan.name} is now active."
    else
      redirect_to with_shopify_navigation_params(plans_path), alert: "The subscription was not approved. No charge was activated."
    end
  rescue ShopifyBilling::Error => error
    redirect_to with_shopify_navigation_params(plans_path), alert: "We could not verify the subscription with Shopify: #{error.message}"
  end
end
