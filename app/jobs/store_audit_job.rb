# frozen_string_literal: true

class StoreAuditJob < ApplicationJob
  queue_as :default

  def perform(audit_id)
    audit = Audit.find(audit_id)
    StoreAuditRunner.new(audit).call
    MerchantEmailNotifications.audit_completed(audit.reload)
  rescue StandardError
    MerchantEmailNotifications.audit_failed(audit.reload) if audit&.persisted?
    raise
  end
end
