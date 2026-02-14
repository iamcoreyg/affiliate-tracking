Gem::Specification.new do |spec|
  spec.name          = "affiliate-tracking"
  spec.version       = "0.1.0"
  spec.authors       = [ "Affiliates" ]
  spec.email         = [ "dev@example.com" ]

  spec.summary       = "Ruby gem for affiliate tracking integration"
  spec.description   = "Read referral cookies, write attribution to Stripe, and notify the affiliate app."
  spec.homepage      = "https://github.com/iamcoreyg/affiliate-tracking"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files         = Dir["lib/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "rack"
  spec.add_dependency "net-http"
end
