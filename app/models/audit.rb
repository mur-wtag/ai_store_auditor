# frozen_string_literal: true

class Audit < ApplicationRecord
  STATUSES = %w[queued running completed failed].freeze
  SOURCES = %w[install manual weekly].freeze

  belongs_to :shop
  has_many :findings, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }

  scope :completed, -> { where(status: "completed") }

  def running!
    update!(status: "running", started_at: Time.current, error_message: nil)
  end

  def failed!(error)
    update!(status: "failed", completed_at: Time.current, error_message: error.to_s.truncate(1_000))
  end

  def top_findings(limit = 10)
    findings.order(Arel.sql("CASE severity WHEN 'critical' THEN 0 WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END"),
      estimated_monthly_revenue_cents: :desc).limit(limit)
  end
end
