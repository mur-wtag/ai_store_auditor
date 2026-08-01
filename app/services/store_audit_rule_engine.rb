# frozen_string_literal: true

class StoreAuditRuleEngine
  CATEGORY_KEYS = %w[homepage product_pages collections seo trust navigation accessibility].freeze
  SEVERITY_PENALTIES = { "critical" => 14, "high" => 9, "medium" => 5, "low" => 2 }.freeze

  attr_reader :snapshot, :monthly_revenue_cents

  def initialize(snapshot:, monthly_revenue_cents:)
    @snapshot = snapshot.deep_stringify_keys
    @monthly_revenue_cents = monthly_revenue_cents.to_i
    @findings = []
  end

  def call
    audit_homepage
    audit_products
    audit_collections
    audit_navigation

    {
      findings: findings,
      category_scores: category_scores,
      overall_score: overall_score,
      estimated_monthly_opportunity_cents: opportunity_cents,
      critical_findings_count: findings.count { |finding| finding[:severity] == "critical" },
      quick_wins_count: findings.count { |finding| finding[:quick_win] }
    }
  end

  private

  attr_reader :findings

  def audit_homepage
    homepage = snapshot["homepage"]
    unless homepage.is_a?(Hash) && homepage["available"] != false
      add_finding(
        category: "homepage", rule_key: "homepage_unavailable", severity: "low",
        title: "Homepage could not be scanned",
        explanation: "The catalog scan completed, but the public homepage was unavailable, password protected, or blocked the scanner.",
        recommendation: "Open the storefront publicly or rerun the audit after the storefront is reachable.",
        evidence: { error: homepage&.dig("error") }, impact_percent: 0, confidence: 1, quick_win: false
      )
      return
    end

    if homepage["h1_count"] != 1
      add_finding(
        category: "homepage", rule_key: "homepage_h1", severity: "high",
        title: "Homepage needs one clear primary heading",
        explanation: "A single descriptive H1 helps shoppers and search engines understand the store's main promise.",
        recommendation: "Use one visible H1 that states what you sell and who it is for.",
        evidence: { h1_count: homepage["h1_count"], headings: homepage["h1_text"] },
        impact_percent: 0.6, confidence: 0.84, quick_win: true, fix_kind: "copy"
      )
    end

    unless homepage["has_cta"]
      add_finding(
        category: "homepage", rule_key: "homepage_cta", severity: "high",
        title: "Homepage has no obvious shopping call to action",
        explanation: "The scan did not find a recognizable shopping action in links or buttons.",
        recommendation: "Place a specific action such as “Shop best sellers” in the first screen and connect it to a focused collection.",
        evidence: { recognized_cta: false }, impact_percent: 0.8, confidence: 0.76, quick_win: true, fix_kind: "theme"
      )
    end

    if homepage["meta_description"].blank?
      add_finding(
        category: "seo", rule_key: "homepage_meta_description", severity: "high",
        title: "Homepage meta description is missing",
        explanation: "Search engines may generate an unpredictable snippet when no description is supplied.",
        recommendation: "Add a distinct 140–160 character summary with the main product category and customer benefit.",
        evidence: { current: homepage["meta_description"] }, impact_percent: 0.3, confidence: 0.9, quick_win: true, fix_kind: "copy"
      )
    end

    unless homepage["has_trust_signals"]
      add_finding(
        category: "trust", rule_key: "homepage_trust", severity: "medium",
        title: "Trust signals are not visible on the homepage",
        explanation: "The page copy did not include common proof such as reviews, guarantees, shipping promises, or easy returns.",
        recommendation: "Add verified social proof and a concise shipping or returns promise near the first purchase path.",
        evidence: { trust_terms_detected: false }, impact_percent: 0.5, confidence: 0.7, quick_win: false, fix_kind: "theme"
      )
    end

    unless homepage["has_mobile_viewport"]
      add_finding(
        category: "homepage", rule_key: "mobile_viewport", severity: "critical",
        title: "Homepage is missing a mobile viewport declaration",
        explanation: "Without a viewport declaration, mobile browsers can render the store at a desktop width.",
        recommendation: "Add a responsive viewport meta tag through the theme layout.",
        evidence: { viewport_detected: false }, impact_percent: 1.2, confidence: 0.98, quick_win: true, fix_kind: "theme"
      )
    end

    image_count = homepage["image_count"].to_i
    alt_coverage = image_count.zero? ? 1 : homepage["images_with_alt_count"].to_f / image_count
    if image_count.positive? && alt_coverage < 0.8
      add_finding(
        category: "accessibility", rule_key: "homepage_alt_coverage", severity: "medium",
        title: "Homepage image alt text coverage is low",
        explanation: "Descriptive alt text helps screen-reader users and gives search engines useful image context.",
        recommendation: "Add meaningful alt text to informative images and leave decorative image alt text empty.",
        evidence: { images: image_count, images_with_alt: homepage["images_with_alt_count"], coverage_percent: (alt_coverage * 100).round },
        impact_percent: 0.2, confidence: 0.93, quick_win: true, fix_kind: "copy"
      )
    end
  end

  def audit_products
    Array(snapshot["products"]).each do |product|
      resource = product_resource(product)
      word_count = product["description"].to_s.scan(/[[:alnum:]]+/).length
      media = Array(product.dig("media", "nodes"))
      image_media = media.select { |item| item["mediaContentType"] == "IMAGE" }

      if word_count < 120
        add_finding(
          **resource, category: "product_pages", rule_key: "product_description_depth", severity: word_count < 40 ? "high" : "medium",
          title: "#{product['title']} needs a more useful description",
          explanation: "The description has #{word_count} words and may not answer the questions a shopper needs before buying.",
          recommendation: "Add benefits, differentiators, specifications, use guidance, shipping, returns, and a short FAQ where relevant.",
          evidence: { word_count: word_count, recommended_minimum: 120 }, impact_percent: 0.35, confidence: 0.82, quick_win: true, fix_kind: "copy"
        )
      end

      if media.length < 3
        add_finding(
          **resource, category: "product_pages", rule_key: "product_media_depth", severity: "high",
          title: "#{product['title']} has too few product visuals",
          explanation: "Only #{media.length} media item#{'s' unless media.length == 1} were found. Multiple angles and in-context images reduce uncertainty.",
          recommendation: "Add clear product angles, scale or lifestyle context, and a detail image before investing in decorative assets.",
          evidence: { media_count: media.length, recommended_minimum: 3 }, impact_percent: 0.5, confidence: 0.8, quick_win: false, fix_kind: "guidance"
        )
      end

      missing_alt = image_media.count { |item| item["alt"].blank? }
      if missing_alt.positive?
        add_finding(
          **resource, category: "accessibility", rule_key: "product_image_alt", severity: "medium",
          title: "#{product['title']} has images without alt text",
          explanation: "#{missing_alt} of #{image_media.length} scanned product images have no alt text.",
          recommendation: "Describe the product and visually important details without keyword stuffing.",
          evidence: { images: image_media.length, missing_alt: missing_alt }, impact_percent: 0.15, confidence: 0.96, quick_win: true, fix_kind: "copy"
        )
      end

      if product.dig("seo", "title").blank?
        add_finding(
          **resource, category: "seo", rule_key: "product_seo_title", severity: "medium",
          title: "#{product['title']} uses the default SEO title",
          explanation: "No dedicated search title is set, so Shopify falls back to the product title.",
          recommendation: "Write a distinct title that combines the product, strongest differentiator, and brand without exceeding the visible result width.",
          evidence: { current_seo_title: nil, fallback_title: product["title"] }, impact_percent: 0.2, confidence: 0.94, quick_win: true, fix_kind: "copy"
        )
      end

      if product.dig("seo", "description").blank?
        add_finding(
          **resource, category: "seo", rule_key: "product_seo_description", severity: "medium",
          title: "#{product['title']} has no SEO description",
          explanation: "The product does not provide a controlled summary for search results.",
          recommendation: "Add a concise benefit-led description that matches the page and avoids unsupported claims.",
          evidence: { current_seo_description: nil }, impact_percent: 0.2, confidence: 0.94, quick_win: true, fix_kind: "copy"
        )
      end
    end
  end

  def audit_collections
    Array(snapshot["collections"]).each do |collection|
      resource = collection_resource(collection)

      if collection["description"].blank?
        add_finding(
          **resource, category: "collections", rule_key: "collection_description", severity: "medium",
          title: "#{collection['title']} collection has no introduction",
          explanation: "A short collection introduction can orient shoppers and add category-level search context.",
          recommendation: "Add two or three useful sentences about what belongs here, who it serves, and how to choose.",
          evidence: { description_present: false }, impact_percent: 0.2, confidence: 0.84, quick_win: true, fix_kind: "copy"
        )
      end

      if collection["image"].blank?
        add_finding(
          **resource, category: "collections", rule_key: "collection_image", severity: "low",
          title: "#{collection['title']} collection has no image",
          explanation: "A relevant collection image improves recognition when the collection appears in navigation or merchandising sections.",
          recommendation: "Add a representative, optimized image that remains legible on mobile.",
          evidence: { image_present: false }, impact_percent: 0.1, confidence: 0.72, quick_win: false, fix_kind: "guidance"
        )
      end
    end
  end

  def audit_navigation
    menus = Array(snapshot["menus"])
    menu_text = menus.flat_map { |menu| flatten_menu_items(menu["items"]) }.map { |item| item["title"].to_s }.join(" ")

    if menus.empty?
      add_finding(
        category: "navigation", rule_key: "navigation_missing", severity: "critical",
        title: "No online-store navigation menus were found",
        explanation: "Shoppers need predictable paths to products, support, and store information.",
        recommendation: "Configure a main menu and footer menu in Shopify Navigation.",
        evidence: { menu_count: 0 }, impact_percent: 1.0, confidence: 0.98, quick_win: false, fix_kind: "settings"
      )
      return
    end

    unless menu_text.match?(/contact|support|help/i)
      add_finding(
        category: "navigation", rule_key: "navigation_support_link", severity: "medium",
        title: "Navigation does not expose a support path",
        explanation: "The scanned menu labels do not include Contact, Support, or Help.",
        recommendation: "Add a clear support link to the header or footer using the label customers are most likely to recognize.",
        evidence: { menu_titles: menus.map { |menu| menu["title"] } }, impact_percent: 0.2, confidence: 0.77, quick_win: true, fix_kind: "settings"
      )
    end
  end

  def flatten_menu_items(items)
    Array(items).flat_map { |item| [ item ] + flatten_menu_items(item["items"]) }
  end

  def product_resource(product)
    {
      resource_type: "Product",
      resource_gid: product["id"],
      resource_title: product["title"],
      resource_url: "/products/#{product['handle']}"
    }
  end

  def collection_resource(collection)
    {
      resource_type: "Collection",
      resource_gid: collection["id"],
      resource_title: collection["title"],
      resource_url: "/collections/#{collection['handle']}"
    }
  end

  def add_finding(category:, rule_key:, severity:, title:, explanation:, recommendation:, evidence:, impact_percent:,
    confidence:, quick_win:, fix_kind: "guidance", resource_type: nil, resource_gid: nil, resource_title: nil, resource_url: nil)
    findings << {
      category: category,
      rule_key: rule_key,
      severity: severity,
      resource_type: resource_type,
      resource_gid: resource_gid,
      resource_title: resource_title,
      resource_url: resource_url,
      title: title,
      explanation: explanation,
      recommendation: recommendation,
      evidence: evidence.compact,
      estimated_lift_percent: impact_percent,
      estimated_monthly_revenue_cents: (monthly_revenue_cents * impact_percent / 100).round,
      confidence: confidence,
      quick_win: quick_win,
      fix_kind: fix_kind
    }
  end

  def category_scores
    @category_scores ||= CATEGORY_KEYS.index_with do |category|
      grouped = findings.select { |finding| finding[:category] == category }.group_by { |finding| finding[:rule_key] }
      deduction = grouped.values.sum do |rule_findings|
        [ rule_findings.sum { |finding| SEVERITY_PENALTIES.fetch(finding[:severity]) }, 24 ].min
      end
      [ 100 - deduction, 0 ].max
    end
  end

  def overall_score
    (category_scores.values.sum.to_f / category_scores.length).round
  end

  def opportunity_cents
    raw = findings.sum { |finding| finding[:estimated_monthly_revenue_cents] }
    [ raw, (monthly_revenue_cents * 0.2).round ].min
  end
end
