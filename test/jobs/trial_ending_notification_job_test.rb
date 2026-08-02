# frozen_string_literal: true

require "test_helper"

class TrialEndingNotificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "notifies an emailable active trial once during the final three days" do
    shop = shops(:regular_shop)
    shop.update!(billing_trial_ends_at: 2.days.from_now, trial_ending_email_sent_at: nil)

    assert_enqueued_emails 1 do
      TrialEndingNotificationJob.perform_now
      TrialEndingNotificationJob.perform_now
    end

    assert shop.reload.trial_ending_email_sent_at.present?
  end

  test "does not notify trials outside the reminder window" do
    shops(:regular_shop).update!(billing_trial_ends_at: 5.days.from_now, trial_ending_email_sent_at: nil)

    assert_no_enqueued_emails { TrialEndingNotificationJob.perform_now }
  end
end
