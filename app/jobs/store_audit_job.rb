# frozen_string_literal: true

class StoreAuditJob < ApplicationJob
  queue_as :default

  def perform(audit_id)
    StoreAuditRunner.new(Audit.find(audit_id)).call
  end
end
