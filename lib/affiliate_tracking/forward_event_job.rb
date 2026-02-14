module AffiliateTracking
  class ForwardEventJob < ActiveJob::Base
    queue_as :default

    def perform(event_type, data_json)
      AffiliateTracking.forward_event(event_type, data_json)
    end
  end
end
