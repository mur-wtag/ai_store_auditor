# frozen_string_literal: true

class FindingsController < AuthenticatedController
  def update
    finding = current_shop.findings.find(params[:id])
    finding.update!(params.expect(finding: [ :status ]))
    redirect_to with_shopify_navigation_params(audit_path(finding.audit)), notice: "Finding updated."
  end
end
