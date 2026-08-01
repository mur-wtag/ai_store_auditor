# frozen_string_literal: true

class AddBillingToShops < ActiveRecord::Migration[8.1]
  def change
    change_table :shops, bulk: true do |t|
      t.string :billing_plan_key
      t.string :billing_status, null: false, default: "none"
      t.string :shopify_app_subscription_id
      t.boolean :billing_test, null: false, default: false
      t.datetime :billing_subscription_created_at
      t.datetime :billing_current_period_end
      t.datetime :billing_trial_ends_at
      t.datetime :billing_first_activated_at
      t.datetime :billing_usage_period_started_at
      t.datetime :billing_synced_at
      t.string :billing_pending_plan_key
      t.string :billing_pending_subscription_id
      t.boolean :partner_development_shop, null: false, default: false
    end

    add_index :shops, :shopify_app_subscription_id, unique: true
  end
end
