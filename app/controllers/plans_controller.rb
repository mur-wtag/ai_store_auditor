# frozen_string_literal: true

class PlansController < AuthenticatedController
  def index
    @plans = BillingPlan.all
    ShopifyBilling.new(current_shop).reconcile!
  rescue ShopifyBilling::Error => error
    @billing_error = error.message
  end
end
