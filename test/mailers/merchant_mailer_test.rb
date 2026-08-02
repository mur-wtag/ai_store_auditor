# frozen_string_literal: true

require "test_helper"

class MerchantMailerTest < ActionMailer::TestCase
  setup do
    @shop = shops(:regular_shop)
    @audit = audits(:completed_audit)
  end

  test "renders the branded welcome email in html and text" do
    mail = MerchantMailer.welcome(@shop.id)

    assert_equal [ @shop.shop_email ], mail.to
    assert_equal "Welcome to Sofenx AI Store Auditor", mail.subject
    assert_includes mail.html_part.body.decoded, "Your store health workspace is ready"
    assert_includes mail.html_part.body.decoded, "#176b45"
    assert_includes mail.text_part.body.decoded, "Open your dashboard"
  end

  test "renders a completed audit summary without exposing internal configuration" do
    mail = MerchantMailer.audit_completed(@audit.id)

    assert_equal "Your store audit is ready: 78/100", mail.subject
    assert_includes mail.html_part.body.decoded, "Travel Mug needs a more useful description"
    assert_includes mail.text_part.body.decoded, "Critical issues: 0"
    assert_not_includes mail.body.decoded, "OPENAI_API_KEY"
  end

  test "renders an audit failure without leaking the internal exception" do
    @audit.update!(status: "failed", error_message: "secret upstream failure")
    mail = MerchantMailer.audit_failed(@audit.id)

    assert_equal "Your store audit needs another try", mail.subject
    assert_includes mail.html_part.body.decoded, "previous audit and finding statuses remain safe"
    assert_not_includes mail.body.decoded, "secret upstream failure"
  end

  test "renders active and ended billing messages" do
    active_mail = MerchantMailer.billing_changed(@shop.id, previous_plan_name: "Free", previous_status: "none")
    assert_equal "Your plan changed to Starter", active_mail.subject
    assert_includes active_mail.html_part.body.decoded, "4 audits"

    @shop.update!(billing_status: "none", billing_plan_key: nil)
    ended_mail = MerchantMailer.billing_changed(@shop.id, previous_plan_name: "Starter", previous_status: "active")
    assert_equal "Your paid AI Store Auditor plan has ended", ended_mail.subject
    assert_includes ended_mail.text_part.body.decoded, "now using Free"
  end

  test "renders audit limit and trial reminders" do
    limit_mail = MerchantMailer.audit_limit_reached(@shop.id)
    assert_includes limit_mail.subject, "audit allowance is used"
    assert_includes limit_mail.text_part.body.decoded, "Allowance refreshes"

    @shop.update!(billing_trial_ends_at: 2.days.from_now)
    trial_mail = MerchantMailer.trial_ending(@shop.id)
    assert_equal "Your Starter trial ends soon", trial_mail.subject
    assert_includes trial_mail.html_part.body.decoded, "$9.99"
  end

  test "renders uninstall confirmation from captured shop attributes" do
    mail = MerchantMailer.app_uninstalled(
      shopify_domain: @shop.shopify_domain,
      shop_name: @shop.shop_name,
      shop_email: @shop.shop_email
    )

    assert_equal "Sofenx AI Store Auditor was uninstalled", mail.subject
    assert_includes mail.html_part.body.decoded, "Store auditing is inactive"
    assert_includes mail.text_part.body.decoded, "Stored app data"
  end
end
