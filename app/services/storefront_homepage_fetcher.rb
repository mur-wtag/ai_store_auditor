# frozen_string_literal: true

require "ipaddr"
require "net/http"
require "resolv"

class StorefrontHomepageFetcher
  class Error < StandardError; end

  MAX_BODY_BYTES = 2.megabytes
  TRUST_TERMS = /review|testimonial|guarantee|secure checkout|free shipping|easy returns|money.back/i
  CTA_TERMS = /shop now|buy now|view products|browse|explore|add to cart|get started/i

  def initialize(url)
    @url = url
  end

  def call
    uri = safe_uri(url)
    response = get(uri)
    raise Error, "Storefront returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
    raise Error, "Storefront HTML exceeded #{MAX_BODY_BYTES} bytes" if response.body.bytesize > MAX_BODY_BYTES

    summarize(response.body)
  rescue URI::InvalidURIError, Resolv::ResolvError, SocketError => error
    raise Error, error.message
  end

  private

  attr_reader :url

  def safe_uri(candidate)
    uri = URI.parse(candidate.to_s)
    raise Error, "Only HTTPS storefront URLs can be scanned" unless uri.is_a?(URI::HTTPS)
    raise Error, "Storefront URL must not contain credentials" if uri.userinfo.present?
    raise Error, "Storefront URL must use port 443" unless uri.port == 443

    addresses = Resolv.getaddresses(uri.host)
    raise Error, "Storefront hostname did not resolve" if addresses.empty?
    raise Error, "Private storefront addresses are not scannable" if addresses.any? { |address| private_address?(address) }

    @resolved_address = addresses.first
    uri
  end

  def private_address?(address)
    ip = IPAddr.new(address)
    private_ranges.any? { |range| range.include?(ip) }
  end

  def private_ranges
    @private_ranges ||= %w[
      0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16
      172.16.0.0/12 192.0.0.0/24 192.168.0.0/16 198.18.0.0/15 224.0.0.0/4
      ::1/128 fc00::/7 fe80::/10 ff00::/8
    ].map { |range| IPAddr.new(range) }
  end

  def get(uri)
    Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      ipaddr: @resolved_address,
      open_timeout: 5,
      read_timeout: 15
    ) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "SofenxAIStoreAuditor/1.0"
      request["Accept"] = "text/html,application/xhtml+xml"
      http.request(request)
    end
  end

  def summarize(html)
    document = Nokogiri::HTML5(html)
    images = document.css("img")
    interactive_text = document.css("a, button, input[type=submit]").map { |node| node.text.presence || node["value"] }.compact.join(" ")
    visible_text = document.at("body")&.text.to_s.squish

    {
      "title" => document.at("title")&.text.to_s.squish,
      "meta_description" => document.at('meta[name="description"]')&.[]("content").to_s.squish,
      "h1_count" => document.css("h1").length,
      "h1_text" => document.css("h1").map { |node| node.text.squish }.reject(&:blank?).first(3),
      "image_count" => images.length,
      "images_with_alt_count" => images.count { |image| image["alt"].present? },
      "has_mobile_viewport" => document.at('meta[name="viewport"]').present?,
      "has_cta" => interactive_text.match?(CTA_TERMS),
      "has_trust_signals" => visible_text.match?(TRUST_TERMS),
      "link_count" => document.css("a[href]").length
    }
  end
end
