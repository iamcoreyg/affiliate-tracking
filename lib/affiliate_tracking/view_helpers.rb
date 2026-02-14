module AffiliateTracking
  module ViewHelpers
    def affiliate_tracking_tag
      config = AffiliateTracking.configuration
      base_url = config.api_url
      domain = config.cookie_domain ? %( domain: "#{config.cookie_domain}",) : ""

      raw <<~HTML
        <script src="#{base_url}/sdk/v1/affiliate-tracking.js"></script>
        <script>AffiliateTracking.init({#{domain} apiUrl: "#{base_url}" });</script>
      HTML
    end
  end
end
