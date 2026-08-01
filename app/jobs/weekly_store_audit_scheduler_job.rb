# frozen_string_literal: true

class WeeklyStoreAuditSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    Shop.find_each do |shop|
      audit = shop.reserve_audit!(source: "weekly")
      StoreAuditJob.perform_later(audit.id)
    rescue Shop::BillingRequired, Shop::AuditLimitReached, Shop::AuditInProgress
      next
    end
  end
end
