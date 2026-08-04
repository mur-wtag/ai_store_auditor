# frozen_string_literal: true

class BillingSubscriptionsController < AuthenticatedController
  def create
    plan = BillingPlan.find!(params[:plan])
    if current_shop.billing_active? && current_shop.billing_plan_key == plan.key
      redirect_to with_shopify_navigation_params(plans_path), notice: "#{plan.name} is already active."
      return
    end

    return_url = "#{callback_billing_subscription_url}?#{shopify_navigation_params.to_query}"
    confirmation_url = ShopifyBilling.new(current_shop).create_subscription!(plan: plan, return_url: return_url)
    redirect_token = billing_redirect_verifier.generate(
      { "shop" => current_shop.shopify_domain, "url" => confirmation_url },
      expires_in: 5.minutes
    )

    redirect_to redirect_billing_subscription_path(
      **shopify_navigation_params,
      token: redirect_token
    ), status: :see_other
  rescue ArgumentError
    redirect_to with_shopify_navigation_params(plans_path), alert: "Choose a valid plan."
  rescue ShopifyBilling::Error => error
    redirect_to with_shopify_navigation_params(plans_path), alert: "Shopify could not start billing: #{error.message}"
  end

  def redirect
    redirect_payload = billing_redirect_verifier.verify(params.require(:token))
    unless ActiveSupport::SecurityUtils.secure_compare(redirect_payload.fetch("shop"), current_shop.shopify_domain)
      raise ActiveSupport::MessageVerifier::InvalidSignature
    end

    redirect_outside_shopify_iframe(redirect_payload.fetch("url"))
  rescue ActiveSupport::MessageVerifier::InvalidSignature, KeyError, ActionController::ParameterMissing
    redirect_to with_shopify_navigation_params(plans_path), alert: "The Shopify billing approval link expired. Please choose the plan again."
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

  def destroy
    unless current_shop.billing_active?
      redirect_to with_shopify_navigation_params(plans_path), notice: "Free is already active."
      return
    end

    ShopifyBilling.new(current_shop).cancel_subscription!
    redirect_to with_shopify_navigation_params(plans_path), notice: "Your paid subscription was cancelled. Free is now active."
  rescue ShopifyBilling::Error => error
    redirect_to with_shopify_navigation_params(plans_path), alert: "Shopify could not cancel the subscription: #{error.message}"
  end

  private

  def billing_redirect_verifier
    Rails.application.message_verifier(:billing_redirect)
  end
end
