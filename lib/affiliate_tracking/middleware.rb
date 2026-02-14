module AffiliateTracking
  class Middleware
    ENV_KEY = "affiliate.ref"

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      cookie_value = request.cookies[COOKIE_NAME]

      if cookie_value && !cookie_value.to_s.strip.empty?
        env[ENV_KEY] = cookie_value.to_s.strip
      end

      @app.call(env)
    end
  end
end
