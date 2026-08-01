# frozen_string_literal: true

require "test_helper"

class OpenaiAuditEnricherTest < ActiveSupport::TestCase
  test "uses the Responses API structured output boundary without storing requests" do
    enricher = OpenaiAuditEnricher.new(api_key: "test-key", model: "gpt-5.6-terra")
    payload = enricher.send(:payload, [ findings(:missing_description) ])

    assert_equal "gpt-5.6-terra", payload[:model]
    assert_equal false, payload[:store]
    assert_equal "low", payload.dig(:reasoning, :effort)
    assert_equal "json_schema", payload.dig(:text, :format, :type)
    assert_equal true, payload.dig(:text, :format, :strict)
    assert_includes payload.dig(:input, 0, :content), "Never promise revenue"
  end
end
