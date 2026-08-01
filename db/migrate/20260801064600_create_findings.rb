class CreateFindings < ActiveRecord::Migration[8.1]
  def change
    create_table :findings do |t|
      t.references :audit, null: false, foreign_key: true
      t.string :category, null: false
      t.string :rule_key, null: false
      t.string :severity, null: false
      t.string :status, default: "open", null: false
      t.string :resource_type
      t.string :resource_gid
      t.string :resource_title
      t.text :resource_url
      t.string :title, null: false
      t.text :explanation, null: false
      t.text :recommendation, null: false
      t.jsonb :evidence, default: {}, null: false
      t.decimal :estimated_lift_percent, precision: 6, scale: 2, default: 0, null: false
      t.bigint :estimated_monthly_revenue_cents, default: 0, null: false
      t.decimal :confidence, precision: 4, scale: 3, default: 0, null: false
      t.boolean :quick_win, default: false, null: false
      t.string :fix_kind, default: "guidance", null: false
      t.jsonb :ai_draft, default: {}, null: false
      t.timestamps
    end

    add_index :findings, [ :audit_id, :severity ]
    add_index :findings, [ :audit_id, :category ]
    add_index :findings, [ :audit_id, :rule_key, :resource_gid ], name: "index_findings_on_audit_rule_and_resource"
  end
end
