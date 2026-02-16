require_relative "engine"

module AffiliateTracking
  class Railtie < Rails::Railtie
    initializer "affiliate_tracking.configure" do
      AffiliateTracking.configure do |config|
        config.api_url = ENV["AFFILIATES_URL"] || (Rails.env.development? ? "http://localhost:3001" : nil)
        config.api_key = ENV["AFFILIATES_API_KEY"]
        config.webhook_secret = ENV["AFFILIATES_WEBHOOK_SECRET"]
        config.cookie_domain = ENV["AFFILIATES_COOKIE_DOMAIN"]
      end
    end

    initializer "affiliate_tracking.view_helpers" do
      ActionView::Base.include AffiliateTracking::ViewHelpers
    end

    initializer "affiliate_tracking.routes", after: :add_routing_paths do |app|
      app.routes.append do
        mount AffiliateTracking::Engine, at: "/affiliate-tracking"
      end
    end
  end
end
