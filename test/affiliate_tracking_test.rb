require "minitest/autorun"
require "rack"
require_relative "../lib/affiliate_tracking"

class AffiliateTrackingTest < Minitest::Test
  def setup
    AffiliateTracking.reset_configuration!
  end

  # Configuration tests

  def test_configure_sets_api_url_and_key
    AffiliateTracking.configure do |config|
      config.api_url = "https://affiliates.example.com"
      config.api_key = "sk_live_test123"
    end

    assert_equal "https://affiliates.example.com", AffiliateTracking.configuration.api_url
    assert_equal "sk_live_test123", AffiliateTracking.configuration.api_key
  end

  def test_default_configuration_has_nil_values
    assert_nil AffiliateTracking.configuration.api_url
    assert_nil AffiliateTracking.configuration.api_key
  end

  def test_reset_configuration
    AffiliateTracking.configure do |config|
      config.api_url = "https://example.com"
    end
    AffiliateTracking.reset_configuration!
    assert_nil AffiliateTracking.configuration.api_url
  end

  # read_ref tests

  def test_read_ref_returns_slug_from_hash
    cookies = { "affiliate_ref" => "justin" }
    assert_equal "justin", AffiliateTracking.read_ref(cookies)
  end

  def test_read_ref_returns_nil_for_missing_cookie
    cookies = {}
    assert_nil AffiliateTracking.read_ref(cookies)
  end

  def test_read_ref_returns_nil_for_nil_cookies
    assert_nil AffiliateTracking.read_ref(nil)
  end

  def test_read_ref_returns_nil_for_empty_cookie_value
    cookies = { "affiliate_ref" => "" }
    assert_nil AffiliateTracking.read_ref(cookies)
  end

  def test_read_ref_returns_nil_for_whitespace_cookie_value
    cookies = { "affiliate_ref" => "   " }
    assert_nil AffiliateTracking.read_ref(cookies)
  end

  def test_read_ref_strips_whitespace
    cookies = { "affiliate_ref" => "  justin  " }
    assert_equal "justin", AffiliateTracking.read_ref(cookies)
  end

  # clear_ref tests

  def test_clear_ref_deletes_cookie
    cookies = MockCookies.new("affiliate_ref" => "justin")
    AffiliateTracking.clear_ref(cookies)
    assert_includes cookies.deleted_keys, "affiliate_ref"
  end

  def test_clear_ref_handles_nil_cookies
    AffiliateTracking.clear_ref(nil)
  end

  def test_clear_ref_handles_hash_without_delete
    cookies = { "affiliate_ref" => "justin" }
    AffiliateTracking.clear_ref(cookies)
    # Should not raise — hash responds to delete
  end

  # attribute tests

  def test_attribute_raises_without_api_url
    AffiliateTracking.configure do |config|
      config.api_key = "test_key"
    end

    assert_raises(AffiliateTracking::ConfigurationError) do
      AffiliateTracking.attribute(stripe_customer_id: "cus_123", slug: "justin")
    end
  end

  def test_attribute_raises_without_api_key
    AffiliateTracking.configure do |config|
      config.api_url = "https://affiliates.example.com"
    end

    assert_raises(AffiliateTracking::ConfigurationError) do
      AffiliateTracking.attribute(stripe_customer_id: "cus_123", slug: "justin")
    end
  end

  def test_attribute_returns_false_for_blank_stripe_customer_id
    AffiliateTracking.configure do |config|
      config.api_url = "https://affiliates.example.com"
      config.api_key = "test_key"
    end

    assert_equal false, AffiliateTracking.attribute(stripe_customer_id: "", slug: "justin")
    assert_equal false, AffiliateTracking.attribute(stripe_customer_id: nil, slug: "justin")
  end

  def test_attribute_returns_false_for_blank_slug
    AffiliateTracking.configure do |config|
      config.api_url = "https://affiliates.example.com"
      config.api_key = "test_key"
    end

    assert_equal false, AffiliateTracking.attribute(stripe_customer_id: "cus_123", slug: "")
    assert_equal false, AffiliateTracking.attribute(stripe_customer_id: "cus_123", slug: nil)
  end

  # Middleware tests

  def test_middleware_sets_env_key_when_cookie_present
    app = ->(env) { [ 200, {}, [ env[AffiliateTracking::Middleware::ENV_KEY].to_s ] ] }
    middleware = AffiliateTracking::Middleware.new(app)

    env = Rack::MockRequest.env_for("/", "HTTP_COOKIE" => "affiliate_ref=justin")
    status, _headers, body = middleware.call(env)

    assert_equal 200, status
    assert_equal "justin", body.first
  end

  def test_middleware_does_not_set_env_key_when_cookie_absent
    app = ->(env) { [ 200, {}, [ env[AffiliateTracking::Middleware::ENV_KEY].to_s ] ] }
    middleware = AffiliateTracking::Middleware.new(app)

    env = Rack::MockRequest.env_for("/")
    status, _headers, body = middleware.call(env)

    assert_equal 200, status
    assert_equal "", body.first
  end

  def test_middleware_does_not_set_env_key_for_empty_cookie
    app = ->(env) { [ 200, {}, [ env[AffiliateTracking::Middleware::ENV_KEY].to_s ] ] }
    middleware = AffiliateTracking::Middleware.new(app)

    env = Rack::MockRequest.env_for("/", "HTTP_COOKIE" => "affiliate_ref=")
    status, _headers, body = middleware.call(env)

    assert_equal 200, status
    assert_equal "", body.first
  end
end

# Mock cookies class that tracks deleted keys
class MockCookies
  attr_reader :deleted_keys

  def initialize(data = {})
    @data = data
    @deleted_keys = []
  end

  def [](key)
    @data[key]
  end

  def delete(key)
    @deleted_keys << key
    @data.delete(key)
  end

  def respond_to?(method, include_all = false)
    [ :[], :delete ].include?(method) || super
  end
end
