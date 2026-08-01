# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  include ShopifyApp::EnsureHasSession unless Rails.env.test?

  layout "embedded_app"
  before_action :load_current_shop
  helper_method :current_shop, :shopify_navigation_params, :with_shopify_navigation_params

  private

  attr_reader :current_shop

  def load_current_shop
    domain = if Rails.env.test?
      params[:shop].presence || Shop.first&.shopify_domain
    elsif respond_to?(:current_shopify_domain, true)
      current_shopify_domain
    end

    @current_shop = Shop.find_by!(shopify_domain: domain)
  end

  def shopify_navigation_params
    {
      shop: current_shop.shopify_domain,
      host: params[:host].presence || Base64.strict_encode64("#{current_shop.shopify_domain}/admin"),
      embedded: params[:embedded].presence || "1"
    }
  end

  def with_shopify_navigation_params(path_or_url)
    separator = path_or_url.include?("?") ? "&" : "?"
    "#{path_or_url}#{separator}#{shopify_navigation_params.to_query}"
  end
end
