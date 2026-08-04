# frozen_string_literal: true

require "net/http"

class ShopifyAdminClient
  class Error < StandardError; end

  MAX_ATTEMPTS = 3

  def initialize(shop_domain, access_token:)
    @shop_domain = shop_domain
    @access_token = access_token
  end

  def audit_snapshot(product_limit: 100, collection_limit: 50, menu_limit: 20)
    response = graphql(<<~GRAPHQL, products: product_limit, collections: collection_limit, menus: menu_limit)
      query StoreAuditSnapshot($products: Int!, $collections: Int!, $menus: Int!) {
        shop {
          name
          email
          currencyCode
          plan { partnerDevelopment }
          primaryDomain { host url }
        }
        products(first: $products, sortKey: UPDATED_AT, reverse: true) {
          nodes {
            id
            title
            handle
            description
            status
            totalInventory
            productType
            vendor
            seo { title description }
            media(first: 10) {
              nodes {
                mediaContentType
                alt
                preview { image { url } }
              }
            }
            variants(first: 20) { nodes { title inventoryQuantity } }
          }
        }
        collections(first: $collections, sortKey: UPDATED_AT, reverse: true) {
          nodes {
            id
            title
            handle
            description
            seo { title description }
            image { url altText }
            productsCount { count }
          }
        }
        menus(first: $menus) {
          nodes {
            id
            title
            handle
            items {
              id
              title
              type
              url
              items { id title type url }
            }
          }
        }
      }
    GRAPHQL

    response.fetch("data")
  end

  def active_app_subscriptions
    response = graphql(<<~GRAPHQL, {})
      query ActiveAppSubscriptions {
        currentAppInstallation {
          activeSubscriptions {
            id
            name
            status
            test
            trialDays
            createdAt
            currentPeriodEnd
          }
        }
      }
    GRAPHQL

    response.dig("data", "currentAppInstallation", "activeSubscriptions") || []
  end

  def partner_development_shop?
    response = graphql(<<~GRAPHQL, {})
      query ShopBillingContext {
        shop {
          plan { partnerDevelopment }
        }
      }
    GRAPHQL

    response.dig("data", "shop", "plan", "partnerDevelopment") == true
  end

  def create_app_subscription(name:, amount:, return_url:, trial_days:, test:)
    variables = {
      name: name,
      amount: amount,
      return_url: return_url,
      trial_days: trial_days,
      test: test
    }

    response = graphql(<<~GRAPHQL, variables)
      mutation CreateAppSubscription(
        $name: String!
        $amount: Decimal!
        $return_url: URL!
        $trial_days: Int!
        $test: Boolean!
      ) {
        appSubscriptionCreate(
          name: $name
          returnUrl: $return_url
          trialDays: $trial_days
          test: $test
          replacementBehavior: STANDARD
          lineItems: [{
            plan: {
              appRecurringPricingDetails: {
                price: { amount: $amount, currencyCode: USD }
                interval: EVERY_30_DAYS
              }
            }
          }]
        ) {
          appSubscription { id }
          confirmationUrl
          userErrors { field message }
        }
      }
    GRAPHQL

    response.dig("data", "appSubscriptionCreate") || {}
  end

  def cancel_app_subscription(id:, prorate: false)
    response = graphql(<<~GRAPHQL, id: id, prorate: prorate)
      mutation CancelAppSubscription($id: ID!, $prorate: Boolean!) {
        appSubscriptionCancel(id: $id, prorate: $prorate) {
          appSubscription { id status }
          userErrors { field message }
        }
      }
    GRAPHQL

    response.dig("data", "appSubscriptionCancel") || {}
  end

  private

  attr_reader :shop_domain, :access_token

  def graphql(query, variables)
    attempts = 0

    begin
      attempts += 1
      response = perform_request(query, variables)
      retryable_response!(response)
      body = JSON.parse(response.body)

      raise Error, body.fetch("errors").to_json if body["errors"].present?
      raise Error, "Shopify returned no data" unless body["data"].is_a?(Hash)

      body
    rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, EOFError, Errno::ECONNRESET, RetryableError => error
      raise Error, "Shopify Admin API failed after #{attempts} attempts: #{error.message}" if attempts >= MAX_ATTEMPTS

      sleep(0.25 * (2**(attempts - 1)))
      retry
    end
  end

  def perform_request(query, variables)
    uri = URI("https://#{shop_domain}/admin/api/#{ShopifyApp.configuration.api_version}/graphql.json")

    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 30) do |http|
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["X-Shopify-Access-Token"] = access_token
      request.body = JSON.generate(query: query, variables: variables)
      http.request(request)
    end
  end

  def retryable_response!(response)
    return if response.is_a?(Net::HTTPSuccess)

    if response.code.to_i == 429 || response.code.to_i >= 500
      raise RetryableError, "HTTP #{response.code}"
    end

    raise Error, "Shopify Admin API returned HTTP #{response.code}: #{response.body.to_s.truncate(500)}"
  end

  class RetryableError < StandardError; end
end
