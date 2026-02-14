module AffiliateTracking
  class Configuration
    attr_accessor :api_url, :api_key, :webhook_secret, :cookie_domain

    def initialize
      @api_url = nil
      @api_key = nil
      @webhook_secret = nil
      @cookie_domain = nil
    end
  end
end
