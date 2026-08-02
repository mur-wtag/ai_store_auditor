# frozen_string_literal: true

require "test_helper"

class MerchantEmailNotificationsTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  setup do
    clear_enqueued_jobs
    @shop = shops(:regular_shop)
    @audit = audits(:completed_audit)
  end

  test "enqueues welcome only once" do
    assert_enqueued_emails 1 do
      MerchantEmailNotifications.welcome(@shop)
      MerchantEmailNotifications.welcome(@shop.reload)
    end

    assert @shop.reload.welcome_email_sent_at.present?
  end

  test "enqueues each completed or failed audit notification only once" do
    assert_enqueued_emails 1 do
      MerchantEmailNotifications.audit_completed(@audit)
      MerchantEmailNotifications.audit_completed(@audit.reload)
    end

    @audit.update!(status: "failed")
    assert_enqueued_emails 1 do
      MerchantEmailNotifications.audit_failed(@audit)
      MerchantEmailNotifications.audit_failed(@audit.reload)
    end
  end

  test "enqueues one audit limit email per usage period" do
    assert_enqueued_emails 1 do
      MerchantEmailNotifications.audit_limit_reached(@shop)
      MerchantEmailNotifications.audit_limit_reached(@shop.reload)
    end

    assert_equal @shop.usage_period_start.to_i, @shop.reload.audit_limit_email_period_started_at.to_i
  end

  test "does not enqueue mail when Shopify has no merchant email" do
    shop = shops(:other_shop)

    assert_no_enqueued_emails { MerchantEmailNotifications.welcome(shop) }
    assert_nil shop.reload.welcome_email_sent_at
  end

  test "enqueues billing mail only for a state or plan change" do
    assert_enqueued_emails 1 do
      MerchantEmailNotifications.billing_changed(
        @shop,
        previous_status: "none",
        previous_plan_key: nil
      )
      MerchantEmailNotifications.billing_changed(
        @shop,
        previous_status: @shop.billing_status,
        previous_plan_key: @shop.billing_plan_key
      )
    end
  end
end
