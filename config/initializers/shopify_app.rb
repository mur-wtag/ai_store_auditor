shopify_app_host = ENV["HOST"].presence || ENV["SHOPIFY_APP_URL"].presence || "http://localhost:3000"
shopify_app_host = "https://#{shopify_app_host}" unless shopify_app_host.match?(%r{\Ahttps?://})

shopify_api_key = ENV.fetch("SHOPIFY_API_KEY", "").presence
shopify_api_secret = ENV.fetch("SHOPIFY_API_SECRET", "").presence
managed_webhooks = ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOPIFY_MANAGED_WEBHOOKS", "false"))
expiring_offline_tokens = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("SHOPIFY_EXPIRING_OFFLINE_ACCESS_TOKENS", "true")
)

# Keep development and test bootable before the app is linked in Shopify Partners.
unless Rails.env.production?
  shopify_api_key ||= "dev-api-key"
  shopify_api_secret ||= "dev-api-secret"
end

ShopifyApp.configure do |config|
  config.application_name = ENV.fetch("SHOPIFY_APP_NAME", "Sofenx AI Store Auditor")
  config.root_url = "/"
  config.login_url = "/login"
  config.scope = ENV.fetch(
    "SHOPIFY_APP_SCOPES",
    "read_products,read_online_store_navigation"
  )
  config.embedded_app = ActiveModel::Type::Boolean.new.cast(ENV.fetch("SHOPIFY_EMBEDDED_APP", "true"))
  config.new_embedded_auth_strategy = config.embedded_app
  config.after_authenticate_job = { job: "Shopify::AfterAuthenticateJob", inline: false }
  config.api_version = ENV.fetch("SHOPIFY_ADMIN_API_VERSION", "2026-07")
  config.shop_session_repository = "Shop"
  config.webhook_jobs_namespace = "ShopifyWebhooks"
  config.log_level = :info
  config.reauth_on_access_scope_changes = true
  config.webhooks = if managed_webhooks
    [
      { topic: "app/uninstalled", path: "webhooks/app_uninstalled" },
      { topic: "customers/data_request", path: "webhooks/customers_data_request" },
      { topic: "customers/redact", path: "webhooks/customers_redact" },
      { topic: "shop/redact", path: "webhooks/shop_redact" }
    ]
  else
    []
  end
  config.api_key = shopify_api_key
  config.secret = shopify_api_secret
end

Rails.application.config.after_initialize do
  next if ShopifyApp.configuration.api_key.blank? || ShopifyApp.configuration.secret.blank?

  ShopifyAPI::Context.setup(
    api_key: ShopifyApp.configuration.api_key,
    api_secret_key: ShopifyApp.configuration.secret,
    api_version: ShopifyApp.configuration.api_version,
    host: shopify_app_host,
    scope: ShopifyApp.configuration.scope,
    is_private: false,
    is_embedded: ShopifyApp.configuration.embedded_app,
    expiring_offline_access_tokens: expiring_offline_tokens,
    log_level: ShopifyApp.configuration.log_level,
    logger: Rails.logger,
    user_agent_prefix: "ShopifyApp/#{ShopifyApp::VERSION}"
  )

  ShopifyApp::WebhooksManager.add_registrations
end
