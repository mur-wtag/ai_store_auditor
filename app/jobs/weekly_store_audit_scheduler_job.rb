# frozen_string_literal: true

class WeeklyStoreAuditSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    Shop.find_each do |shop|
      next if shop.audit_in_progress?

      audit = shop.audits.create!(source: "weekly")
      StoreAuditJob.perform_later(audit.id)
    end
  end
end
