module AffiliateTracking
  module ViewHelpers
    def affiliate_tracking_tag
      config = AffiliateTracking.configuration
      base_url = config.api_url
      domain = config.cookie_domain || derive_cookie_domain

      domain_param = domain ? %( domain: "#{domain}",) : ""

      raw <<~HTML
        <script src="#{base_url}/sdk/v1/affiliate-tracking.js"></script>
        <script>if (typeof AffiliateTracking !== "undefined") { AffiliateTracking.init({#{domain_param} apiUrl: "#{base_url}" }); }</script>
      HTML
    end

    private

    def derive_cookie_domain
      return nil unless respond_to?(:request) && request.present?

      host = request.host
      host.sub(/\Awww\./, "")
    end
  end
end
