require "net/http"
require "json"
require "uri"
require "openssl"

require_relative "affiliate_tracking/configuration"
require_relative "affiliate_tracking/client"
require_relative "affiliate_tracking/middleware"
require_relative "affiliate_tracking/view_helpers"

if defined?(Rails)
  require_relative "affiliate_tracking/railtie"
  require_relative "affiliate_tracking/forward_event_job"
end

module AffiliateTracking
  COOKIE_NAME = "affiliate_ref"

  FORWARDED_EVENTS = %w[
    invoice.paid
    charge.refunded
    customer.subscription.deleted
    promotion_code.created
    promotion_code.updated
  ].freeze

  class Error < StandardError; end
  class ConfigurationError < Error; end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end

    # Read the referral slug from cookies
    # @param cookies [Hash, ActionDispatch::Cookies] cookie jar or hash
    # @return [String, nil] the referral slug or nil
    def read_ref(cookies)
      return nil if cookies.nil?

      value = cookies[COOKIE_NAME]
      return nil if value.nil? || value.to_s.strip.empty?

      value.to_s.strip
    end

    # Attribute a Stripe customer to an affiliate
    # Writes metadata.referred_by to the Stripe customer and notifies the affiliate app
    # @param stripe_customer_id [String] the Stripe customer ID
    # @param slug [String] the affiliate slug
    # @return [Boolean] true if attribution succeeded
    def attribute(stripe_customer_id:, slug:)
      raise ConfigurationError, "api_url is not configured" if configuration.api_url.nil? || configuration.api_url.empty?
      raise ConfigurationError, "api_key is not configured" if configuration.api_key.nil? || configuration.api_key.empty?

      return false if stripe_customer_id.nil? || stripe_customer_id.to_s.strip.empty?
      return false if slug.nil? || slug.to_s.strip.empty?

      # Write metadata to Stripe customer (first touch wins)
      customer = Stripe::Customer.retrieve(stripe_customer_id)
      existing_ref = customer.metadata["Link"]

      if existing_ref.nil? || existing_ref.to_s.strip.empty?
        Stripe::Customer.update(stripe_customer_id, {
          metadata: { Link: slug }
        })
      end

      # Notify the affiliate app via API
      Client.notify_attribution(
        stripe_customer_id: stripe_customer_id,
        slug: slug
      )

      true
    end

    # Forward a Stripe event to the affiliate app (HMAC-signed)
    # @param event_type [String] e.g. "invoice.paid"
    # @param data_json [String] JSON string of the Stripe data object
    # @return [Boolean] true if forwarding succeeded
    def forward_event(event_type, data_json)
      return false if configuration.api_url.nil? || configuration.api_url.empty?
      return false if configuration.webhook_secret.nil? || configuration.webhook_secret.empty?

      payload = { event_type: event_type, data: JSON.parse(data_json) }.to_json
      signature = OpenSSL::HMAC.hexdigest("SHA256", configuration.webhook_secret, payload)

      uri = URI.parse("#{configuration.api_url.chomp("/")}/api/v1/events")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 10
      http.read_timeout = 15

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["X-Webhook-Signature"] = signature
      request.body = payload

      response = http.request(request)
      response.is_a?(Net::HTTPSuccess)
    end

    # Check if a Stripe event type should be forwarded
    # @param event_type [String]
    # @return [Boolean]
    def forward_event?(event_type)
      secret = configuration.webhook_secret
      !(secret.nil? || secret.to_s.strip.empty?) && FORWARDED_EVENTS.include?(event_type)
    end

    # Forward a Stripe event async if it's affiliate-relevant
    # Call this from your Stripe webhook controller with the raw event object
    # @param event [Stripe::Event] the Stripe event
    def forward_stripe_event(event)
      return unless forward_event?(event.type)

      ForwardEventJob.perform_later(event.type, event.data.object.to_json)
    end

    # Clear the referral cookie after attribution
    # @param cookies [Hash, ActionDispatch::Cookies] cookie jar
    def clear_ref(cookies)
      return if cookies.nil?

      if cookies.respond_to?(:delete)
        cookies.delete(COOKIE_NAME)
      end
    end
  end
end
