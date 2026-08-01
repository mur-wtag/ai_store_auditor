# frozen_string_literal: true

class AuditsController < AuthenticatedController
  def create
    if current_shop.audit_in_progress?
      redirect_to with_shopify_navigation_params(root_path), alert: "A store audit is already running."
      return
    end

    audit = current_shop.audits.create!(source: "manual")
    StoreAuditJob.perform_later(audit.id)
    redirect_to with_shopify_navigation_params(audit_path(audit)), notice: "Store audit started."
  end

  def show
    @audit = current_shop.audits.find(params[:id])
    render "dashboard/show"
  end
end
