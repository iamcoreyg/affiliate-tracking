module AffiliateTracking
  class HandshakeController < ActionController::API
    def verify
      challenge = params[:challenge].to_s
      api_key_digests = Array(params[:api_key_digests])
      webhook_signatures = Array(params[:webhook_signatures])

      api_key_match = check_api_key(api_key_digests)
      webhook_secret_match = check_webhook_secret(challenge, webhook_signatures)

      render json: {
        api_key_match: api_key_match,
        webhook_secret_match: webhook_secret_match
      }
    end

    private

    def check_api_key(digests)
      raw_key = ENV["AFFILIATES_API_KEY"]
      return false if raw_key.blank?

      our_digest = Digest::SHA256.hexdigest(raw_key)
      digests.any? { |d| ActiveSupport::SecurityUtils.secure_compare(our_digest, d.to_s) }
    end

    def check_webhook_secret(challenge, signatures)
      raw_secret = ENV["AFFILIATES_WEBHOOK_SECRET"]
      return false if raw_secret.blank? || challenge.blank?

      our_signature = OpenSSL::HMAC.hexdigest("SHA256", raw_secret, challenge)
      signatures.any? { |s| ActiveSupport::SecurityUtils.secure_compare(our_signature, s.to_s) }
    end
  end
end
