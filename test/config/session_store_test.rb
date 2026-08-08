# frozen_string_literal: true

require "test_helper"

class SessionStoreTest < ActiveSupport::TestCase
  test "production sessions support Shopify's cross-site iframe" do
    source = Rails.root.join("config/initializers/session_store.rb").read

    assert_includes source, "secure: Rails.env.production?"
    assert_includes source, "same_site: Rails.env.production? ? :none : :lax"
  end
end
