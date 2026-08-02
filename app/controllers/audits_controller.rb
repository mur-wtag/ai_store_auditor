# frozen_string_literal: true

class AuditsController < AuthenticatedController
  def create
    audit = current_shop.reserve_audit!(source: "manual")
    StoreAuditJob.perform_later(audit.id)
    redirect_to with_shopify_navigation_params(audit_path(audit)), notice: "Store audit started."
  rescue Shop::AuditLimitReached => error
    redirect_to with_shopify_navigation_params(plans_path), alert: error.message
  rescue Shop::AuditInProgress => error
    redirect_to with_shopify_navigation_params(root_path), alert: error.message
  end

  def show
    @audit = current_shop.audits.find(params[:id])
    render "dashboard/show"
  end
end
