class CreateAudits < ActiveRecord::Migration[8.1]
  def change
    create_table :audits do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :status, default: "queued", null: false
      t.string :source, default: "manual", null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :overall_score
      t.jsonb :category_scores, default: {}, null: false
      t.bigint :estimated_monthly_opportunity_cents, default: 0, null: false
      t.integer :critical_findings_count, default: 0, null: false
      t.integer :quick_wins_count, default: 0, null: false
      t.integer :resources_scanned_count, default: 0, null: false
      t.string :ai_model
      t.jsonb :snapshot_summary, default: {}, null: false
      t.text :error_message
      t.timestamps
    end

    add_index :audits, [ :shop_id, :created_at ]
    add_index :audits, [ :shop_id, :status ]
  end
end
