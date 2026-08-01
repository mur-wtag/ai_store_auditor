# frozen_string_literal: true

class DashboardController < AuthenticatedController
  def show
    @audit = current_shop.latest_audit
  end
end
