class CreateShops < ActiveRecord::Migration[8.1]
  def self.up
    create_table :shops do |t|
      t.string :shopify_domain, null: false
      t.string :shopify_token, null: false
      t.string :shop_name
      t.string :shop_email
      t.string :primary_domain_url
      t.string :currency_code
      t.string :locale
      t.bigint :monthly_revenue_cents, default: 0, null: false
      t.integer :current_score
      t.datetime :last_audited_at
      t.datetime :uninstalled_at
      t.jsonb :scan_preferences, default: {}, null: false
      t.timestamps
    end

    add_index :shops, :shopify_domain, unique: true
  end

  def self.down
    drop_table :shops
  end
end
