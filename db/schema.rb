# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_02_043000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audits", force: :cascade do |t|
    t.string "ai_model"
    t.jsonb "category_scores", default: {}, null: false
    t.datetime "completed_at"
    t.datetime "completion_email_sent_at"
    t.datetime "created_at", null: false
    t.integer "critical_findings_count", default: 0, null: false
    t.text "error_message"
    t.bigint "estimated_monthly_opportunity_cents", default: 0, null: false
    t.datetime "failure_email_sent_at"
    t.integer "overall_score"
    t.integer "quick_wins_count", default: 0, null: false
    t.integer "resources_scanned_count", default: 0, null: false
    t.bigint "shop_id", null: false
    t.jsonb "snapshot_summary", default: {}, null: false
    t.string "source", default: "manual", null: false
    t.datetime "started_at"
    t.string "status", default: "queued", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "created_at"], name: "index_audits_on_shop_id_and_created_at"
    t.index ["shop_id", "status"], name: "index_audits_on_shop_id_and_status"
    t.index ["shop_id"], name: "index_audits_on_shop_id"
  end

  create_table "findings", force: :cascade do |t|
    t.jsonb "ai_draft", default: {}, null: false
    t.bigint "audit_id", null: false
    t.string "category", null: false
    t.decimal "confidence", precision: 4, scale: 3, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.decimal "estimated_lift_percent", precision: 6, scale: 2, default: "0.0", null: false
    t.bigint "estimated_monthly_revenue_cents", default: 0, null: false
    t.jsonb "evidence", default: {}, null: false
    t.text "explanation", null: false
    t.string "fix_kind", default: "guidance", null: false
    t.boolean "quick_win", default: false, null: false
    t.text "recommendation", null: false
    t.string "resource_gid"
    t.string "resource_title"
    t.string "resource_type"
    t.text "resource_url"
    t.string "rule_key", null: false
    t.string "severity", null: false
    t.string "status", default: "open", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["audit_id", "category"], name: "index_findings_on_audit_id_and_category"
    t.index ["audit_id", "rule_key", "resource_gid"], name: "index_findings_on_audit_rule_and_resource"
    t.index ["audit_id", "severity"], name: "index_findings_on_audit_id_and_severity"
    t.index ["audit_id"], name: "index_findings_on_audit_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "access_scopes", default: "", null: false
    t.datetime "audit_limit_email_period_started_at"
    t.datetime "billing_current_period_end"
    t.datetime "billing_first_activated_at"
    t.string "billing_pending_plan_key"
    t.string "billing_pending_subscription_id"
    t.string "billing_plan_key"
    t.string "billing_status", default: "none", null: false
    t.datetime "billing_subscription_created_at"
    t.datetime "billing_synced_at"
    t.boolean "billing_test", default: false, null: false
    t.datetime "billing_trial_ends_at"
    t.datetime "billing_usage_period_started_at"
    t.datetime "created_at", null: false
    t.string "currency_code"
    t.integer "current_score"
    t.datetime "expires_at"
    t.datetime "last_audited_at"
    t.string "locale"
    t.bigint "monthly_revenue_cents", default: 0, null: false
    t.boolean "partner_development_shop", default: false, null: false
    t.string "primary_domain_url"
    t.string "refresh_token"
    t.datetime "refresh_token_expires_at"
    t.jsonb "scan_preferences", default: {}, null: false
    t.string "shop_email"
    t.string "shop_name"
    t.string "shopify_app_subscription_id"
    t.string "shopify_domain", null: false
    t.string "shopify_token", null: false
    t.datetime "trial_ending_email_sent_at"
    t.datetime "uninstalled_at"
    t.datetime "updated_at", null: false
    t.datetime "welcome_email_sent_at"
    t.index ["shopify_app_subscription_id"], name: "index_shops_on_shopify_app_subscription_id", unique: true
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true
  end

  add_foreign_key "audits", "shops"
  add_foreign_key "findings", "audits"
end
