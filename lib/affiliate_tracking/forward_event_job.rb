module AffiliateTracking
  class ForwardEventJob < ActiveJob::Base
    queue_as :default

    def perform(event_type, data_json)
      logger.info "[AffiliateTracking] Forwarding event: #{event_type}"
      result = AffiliateTracking.forward_event(event_type, data_json)
      if result
        logger.info "[AffiliateTracking] Successfully forwarded #{event_type}"
      else
        logger.warn "[AffiliateTracking] Failed to forward #{event_type} — check AFFILIATES_APP_URL and AFFILIATES_WEBHOOK_SECRET"
      end
      result
    end
  end
end
