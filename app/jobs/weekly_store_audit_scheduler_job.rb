# frozen_string_literal: true

class WeeklyStoreAuditSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    Shop.find_each do |shop|
      audit = shop.reserve_audit!(source: "weekly")
      StoreAuditJob.perform_later(audit.id)
    rescue Shop::AuditLimitReached
      MerchantEmailNotifications.audit_limit_reached(shop)
      next
    rescue Shop::AuditInProgress
      next
    end
  end
end
