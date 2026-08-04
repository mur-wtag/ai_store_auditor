# frozen_string_literal: true

require "test_helper"

class PublicLegalControllerTest < ActionDispatch::IntegrationTest
  test "publishes a complete privacy policy" do
    get privacy_url

    assert_response :success
    assert_select "h1", "Privacy policy"
    assert_select "body", text: /support@sofenx\.com/
    assert_select "body", text: /OpenAI/
    assert_select "body", text: /up to 30 days/
    assert_select "body", text: /development draft|before launch|add the production/i, count: 0
  end

  test "publishes complete terms" do
    get terms_url

    assert_response :success
    assert_select "h1", "Terms of service"
    assert_select "body", text: /downgrade to Free/
    assert_select "body", text: /support@sofenx\.com/
    assert_select "body", text: /development draft|not ready for publication/i, count: 0
  end

  test "publishes monitored support details" do
    get support_url

    assert_response :success
    assert_select "h1", "Support"
    assert_select "body", text: /support@sofenx\.com/
    assert_select "body", text: /two business days/
    assert_select "body", text: /development placeholder|before App Store submission/i, count: 0
  end
end
