# AffiliateTracking Ruby Gem

Server-side integration gem for the affiliate tracking system. Reads referral cookies set by the JS SDK, writes attribution metadata to Stripe customers, forwards Stripe events, and provides a cross-app handshake endpoint for verifying connectivity.

## Installation

```ruby
# Gemfile (main app)
gem "affiliate-tracking", github: "iamcoreyg/affiliate-tracking", require: "affiliate_tracking"
```

## Environment Variables

Set these in your main app's `.env`:

| Variable | Required | Purpose |
|---|---|---|
| `AFFILIATES_APP_URL` | Yes | URL of the affiliates app (e.g. `http://localhost:3001`) |
| `AFFILIATES_API_KEY` | Yes | Raw API key from affiliates admin → Settings → API Keys |
| `AFFILIATES_WEBHOOK_SECRET` | Yes | Raw secret from affiliates admin → Settings → Inbound Webhooks |
| `AFFILIATES_COOKIE_DOMAIN` | Optional | Cookie domain for the tracking cookie |

The gem's Railtie auto-configures from these env vars — no initializer file needed.

## Usage

### In your signup controller

```ruby
slug = AffiliateTracking.read_ref(cookies)
AffiliateTracking.attribute(stripe_customer_id: customer.id, slug: slug) if slug
AffiliateTracking.clear_ref(cookies)
```

### In your Stripe webhook controller

```ruby
AffiliateTracking.forward_stripe_event(event)
```

Automatically forwards affiliate-relevant events (`invoice.paid`, `charge.refunded`, etc.) to the affiliates app via HMAC-signed POST.

### View helper (tracking tag)

```erb
<%= affiliate_tracking_tag %>
```

Renders the JS SDK script tag that handles `?via=` referral links and sets cookies.

## API

- `AffiliateTracking.read_ref(cookies)` — Returns the referral slug from the `affiliate_ref` cookie, or nil
- `AffiliateTracking.attribute(stripe_customer_id:, slug:)` — Writes `metadata.Link` to Stripe customer and notifies affiliate app via `POST /api/v1/attributions`
- `AffiliateTracking.clear_ref(cookies)` — Clears the referral cookie after attribution
- `AffiliateTracking.forward_stripe_event(event)` — Checks if event is affiliate-relevant, enqueues HMAC-signed forwarding job
- `AffiliateTracking.forward_event(event_type, data_json)` — Direct event forwarding (used by the job)

## Rails Engine

The gem includes a Rails Engine that auto-mounts at `/affiliate-tracking`. It provides:

- `POST /affiliate-tracking/handshake` — Cross-app credential verification endpoint used by the affiliates app's connection test

## Optional Rack Middleware

```ruby
# config/application.rb
config.middleware.use AffiliateTracking::Middleware
```

Makes `request.env["affiliate.ref"]` available in all controllers.
