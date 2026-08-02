# frozen_string_literal: true

class StoreAuditRunner
  attr_reader :audit, :snapshot_provider

  def initialize(audit, snapshot_provider: nil)
    @audit = audit
    @snapshot_provider = snapshot_provider || ShopifyStoreSnapshot.new(audit.shop)
  end

  def call
    audit.running!
    snapshot = snapshot_provider.call
    result = StoreAuditRuleEngine.new(
      snapshot: snapshot,
      monthly_revenue_cents: audit.shop.monthly_revenue_cents
    ).call

    Audit.transaction do
      audit.findings.delete_all
      audit.findings.create!(result.fetch(:findings))
      audit.update!(audit_attributes(snapshot, result))
      audit.shop.update!(current_score: result.fetch(:overall_score), last_audited_at: Time.current)
    end

    enrich_with_ai
    audit.reload
  rescue StandardError => error
    audit.failed!(error) if audit.persisted?
    raise
  end

  private

  def audit_attributes(snapshot, result)
    {
      status: "completed",
      completed_at: Time.current,
      overall_score: result.fetch(:overall_score),
      category_scores: result.fetch(:category_scores),
      estimated_monthly_opportunity_cents: result.fetch(:estimated_monthly_opportunity_cents),
      critical_findings_count: result.fetch(:critical_findings_count),
      quick_wins_count: result.fetch(:quick_wins_count),
      resources_scanned_count: Array(snapshot["products"]).length + Array(snapshot["collections"]).length + 1,
      snapshot_summary: {
        products: Array(snapshot["products"]).length,
        collections: Array(snapshot["collections"]).length,
        menus: Array(snapshot["menus"]).length,
        homepage_available: snapshot.dig("homepage", "available")
      }
    }
  end

  def enrich_with_ai
    return unless audit.shop.billing_active?
    return unless OpenaiAuditEnricher.available?

    enricher = OpenaiAuditEnricher.new
    enricher.enrich(audit.top_findings(audit.shop.findings_limit))
    audit.update!(ai_model: enricher.model)
  rescue OpenaiAuditEnricher::Error => error
    Rails.logger.warn("Audit #{audit.id} completed without AI enrichment: #{error.message}")
  end
end
