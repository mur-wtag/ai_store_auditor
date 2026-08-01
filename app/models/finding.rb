# frozen_string_literal: true

class Finding < ApplicationRecord
  CATEGORIES = %w[homepage product_pages collections seo trust navigation accessibility].freeze
  SEVERITIES = %w[critical high medium low].freeze
  STATUSES = %w[open in_progress fixed dismissed].freeze
  FIX_KINDS = %w[copy settings theme guidance].freeze

  belongs_to :audit

  validates :category, inclusion: { in: CATEGORIES }
  validates :severity, inclusion: { in: SEVERITIES }
  validates :status, inclusion: { in: STATUSES }
  validates :fix_kind, inclusion: { in: FIX_KINDS }
  validates :rule_key, :title, :explanation, :recommendation, presence: true
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
end
