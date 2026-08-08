# frozen_string_literal: true

class BillingPlan
  Plan = Data.define(:key, :name, :price, :audit_limit, :description, :features) do
    def subscription_name
      "Sofenx AI Store Auditor - #{name}"
    end
  end

  FREE = Plan.new(
    key: "free",
    name: "Free",
    price: 0,
    audit_limit: 1,
    description: "For merchants who want a monthly storefront health check.",
    features: [ "1 full-store audit every 30 days", "Top 5 prioritized fixes", "Evidence-backed recommendations" ]
  )

  PLANS = {
    "starter" => Plan.new(
      key: "starter",
      name: "Starter",
      price: "9.99",
      audit_limit: 4,
      description: "For small stores building a reliable improvement routine.",
      features: [ "4 full-store audits every 30 days", "Top 10 prioritized fixes", "AI-assisted copy and implementation guidance" ]
    ),
    "growth" => Plan.new(
      key: "growth",
      name: "Growth",
      price: "19.99",
      audit_limit: 15,
      description: "For growing brands that iterate on merchandising every week.",
      features: [ "15 full-store audits every 30 days", "Top 10 prioritized fixes", "AI-assisted copy and implementation guidance" ]
    ),
    "pro" => Plan.new(
      key: "pro",
      name: "Pro",
      price: "39.99",
      audit_limit: 31,
      description: "For established brands that want daily storefront oversight.",
      features: [ "31 full-store audits every 30 days", "Top 10 prioritized fixes", "AI-assisted copy and implementation guidance" ]
    )
  }.freeze

  TRIAL_DAYS = 7
  TRIAL_AUDIT_LIMIT = 1

  class << self
    def all
      [ FREE, *paid ]
    end

    def paid
      PLANS.values
    end

    def find(key)
      PLANS[key.to_s]
    end

    def find!(key)
      find(key) || raise(ArgumentError, "Unknown billing plan")
    end

    def free
      FREE
    end

    def from_subscription_name(name)
      paid.find { |plan| plan.subscription_name == name }
    end
  end
end
