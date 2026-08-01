# frozen_string_literal: true

class SettingsController < AuthenticatedController
  def edit
  end

  def update
    monthly_revenue = params.expect(settings: [ :monthly_revenue ])[:monthly_revenue]
    dollars = BigDecimal(monthly_revenue.presence || "0")
    current_shop.update!(monthly_revenue_cents: (dollars * 100).round)
    redirect_to with_shopify_navigation_params(root_path), notice: "Revenue baseline saved. Future opportunity estimates will use it."
  rescue ArgumentError
    flash.now[:alert] = "Enter monthly revenue as a number."
    render :edit, status: :unprocessable_entity
  end
end
