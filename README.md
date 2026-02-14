# AffiliateTracking Ruby Gem

Server-side integration gem for the affiliate tracking system. Reads referral cookies set by the JS SDK, writes attribution metadata to Stripe customers, and notifies the affiliate app.

## Installation

```ruby
gem "affiliate-tracking", path: "gems/affiliate-tracking"
```

## Configuration

```ruby
# config/initializers/affiliate_tracking.rb
AffiliateTracking.configure do |config|
  config.api_url = ENV["AFFILIATES_URL"]
  config.api_key = ENV["AFFILIATES_API_KEY"]
  config.cookie_domain = ENV["AFFILIATES_COOKIE_DOMAIN"]
end
```

## Usage

### In your signup controller

```ruby
slug = AffiliateTracking.read_ref(cookies)
AffiliateTracking.attribute(stripe_customer_id: customer.id, slug: slug) if slug
AffiliateTracking.clear_ref(cookies)
```

### API

- `AffiliateTracking.read_ref(cookies)` — Returns the referral slug from the `affiliate_ref` cookie, or nil
- `AffiliateTracking.attribute(stripe_customer_id:, slug:)` — Writes `metadata.referred_by` to Stripe customer and notifies affiliate app via `POST /api/v1/attributions`
- `AffiliateTracking.clear_ref(cookies)` — Clears the referral cookie after attribution
- `AffiliateTracking.getRef()` (JS SDK) — Returns the current referral slug from the cookie

### Optional Rack Middleware

```ruby
# config/application.rb
config.middleware.use AffiliateTracking::Middleware
```

Makes `request.env["affiliate.ref"]` available in all controllers.
