# frozen_string_literal: true

require "test_helper"

class AuditTest < ActiveSupport::TestCase
  test "top findings use their id as a stable tie breaker" do
    audit = audits(:completed_audit)
    existing = findings(:missing_description)
    existing.update!(estimated_monthly_revenue_cents: 0)
    later = audit.findings.create!(existing.attributes.except("id", "created_at", "updated_at").merge(
      title: "Another tied finding",
      resource_gid: "gid://shopify/Product/2"
    ))

    assert_equal [ existing.id, later.id ], audit.top_findings(2).pluck(:id)
  end
end
