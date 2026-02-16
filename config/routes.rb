AffiliateTracking::Engine.routes.draw do
  post "handshake", to: "handshake#verify"
end
