# frozen_string_literal: true

class BillingPlan
  Plan = Data.define(:key, :name, :price, :audit_limit, :description, :features) do
    def subscription_name
      "Sofenx AI Store Auditor - #{name}"
    end
  end

  PLANS = {
    "starter" => Plan.new(
      key: "starter",
      name: "Starter",
      price: 19,
      audit_limit: 4,
      description: "For small stores building a reliable improvement routine.",
      features: [ "4 full-store audits every 30 days", "Top 10 prioritized fixes", "AI-assisted copy and implementation guidance" ]
    ),
    "growth" => Plan.new(
      key: "growth",
      name: "Growth",
      price: 49,
      audit_limit: 15,
      description: "For growing brands that iterate on merchandising every week.",
      features: [ "15 full-store audits every 30 days", "Top 10 prioritized fixes", "AI-assisted copy and implementation guidance" ]
    ),
    "pro" => Plan.new(
      key: "pro",
      name: "Pro",
      price: 99,
      audit_limit: 31,
      description: "For established brands that want daily storefront oversight.",
      features: [ "31 full-store audits every 30 days", "Top 10 prioritized fixes", "AI-assisted copy and implementation guidance" ]
    )
  }.freeze

  TRIAL_DAYS = 7

  class << self
    def all
      PLANS.values
    end

    def find(key)
      PLANS[key.to_s]
    end

    def find!(key)
      find(key) || raise(ArgumentError, "Unknown billing plan")
    end

    def from_subscription_name(name)
      all.find { |plan| plan.subscription_name == name }
    end
  end
end
