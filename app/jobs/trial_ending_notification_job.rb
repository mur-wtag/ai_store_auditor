# frozen_string_literal: true

class TrialEndingNotificationJob < ApplicationJob
  queue_as :default

  def perform
    Shop.where(billing_status: "active", trial_ending_email_sent_at: nil)
      .where(billing_trial_ends_at: Time.current..3.days.from_now)
      .find_each { |shop| MerchantEmailNotifications.trial_ending(shop) }
  end
end
