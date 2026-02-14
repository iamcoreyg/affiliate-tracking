module AffiliateTracking
  class Client
    # Notify the affiliate app about a new attribution
    # POST /api/v1/attributions
    # @param stripe_customer_id [String]
    # @param slug [String]
    # @return [Boolean] true if notification was accepted
    def self.notify_attribution(stripe_customer_id:, slug:)
      config = AffiliateTracking.configuration
      uri = URI.join(config.api_url.chomp("/") + "/", "api/v1/attributions")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{config.api_key}"
      request.body = JSON.generate({
        stripe_customer_id: stripe_customer_id,
        slug: slug
      })

      response = http.request(request)
      response.code.to_i == 200
    rescue StandardError
      false
    end
  end
end
