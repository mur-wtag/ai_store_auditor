# frozen_string_literal: true

class AddEmailNotificationTracking < ActiveRecord::Migration[8.1]
  def change
    add_column :shops, :welcome_email_sent_at, :datetime
    add_column :shops, :trial_ending_email_sent_at, :datetime
    add_column :shops, :audit_limit_email_period_started_at, :datetime

    add_column :audits, :completion_email_sent_at, :datetime
    add_column :audits, :failure_email_sent_at, :datetime
  end
end
