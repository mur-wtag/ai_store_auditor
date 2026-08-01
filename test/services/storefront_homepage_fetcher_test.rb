# frozen_string_literal: true

require "test_helper"

class StorefrontHomepageFetcherTest < ActiveSupport::TestCase
  test "rejects non HTTPS URLs" do
    error = assert_raises(StorefrontHomepageFetcher::Error) do
      StorefrontHomepageFetcher.new("http://example.com").call
    end

    assert_includes error.message, "HTTPS"
  end

  test "rejects loopback addresses before making a request" do
    error = assert_raises(StorefrontHomepageFetcher::Error) do
      StorefrontHomepageFetcher.new("https://127.0.0.1").call
    end

    assert_includes error.message, "Private storefront"
  end
end
