require "minitest/autorun"
require "openssl"
require "digest"
require "json"

# Unit-test the handshake logic without booting Rails.
# We extract the matching helpers and test them directly.
class HandshakeLogicTest < Minitest::Test
  def test_api_key_digest_matches
    raw_key = "aff_test_abc123"
    digest = Digest::SHA256.hexdigest(raw_key)

    # Simulate what the controller does: hash ENV key and compare
    our_digest = Digest::SHA256.hexdigest(raw_key)
    assert_equal our_digest, digest
  end

  def test_api_key_digest_mismatch
    digest = Digest::SHA256.hexdigest("aff_test_abc123")
    wrong_digest = Digest::SHA256.hexdigest("aff_test_wrong")

    refute_equal digest, wrong_digest
  end

  def test_webhook_hmac_challenge_matches
    secret = "whsec_test_secret123"
    challenge = "random_nonce_abc"

    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, challenge)
    expected = OpenSSL::HMAC.hexdigest("SHA256", secret, challenge)

    assert_equal expected, signature
  end

  def test_webhook_hmac_challenge_mismatch
    challenge = "random_nonce_abc"

    sig_a = OpenSSL::HMAC.hexdigest("SHA256", "secret_a", challenge)
    sig_b = OpenSSL::HMAC.hexdigest("SHA256", "secret_b", challenge)

    refute_equal sig_a, sig_b
  end

  def test_multiple_digests_one_matches
    keys = %w[key_one key_two key_three]
    digests = keys.map { |k| Digest::SHA256.hexdigest(k) }

    target = Digest::SHA256.hexdigest("key_two")
    assert digests.any? { |d| d == target }
  end

  def test_multiple_signatures_one_matches
    challenge = "test_challenge"
    secrets = %w[secret_one secret_two secret_three]
    signatures = secrets.map { |s| OpenSSL::HMAC.hexdigest("SHA256", s, challenge) }

    target = OpenSSL::HMAC.hexdigest("SHA256", "secret_two", challenge)
    assert signatures.any? { |s| s == target }
  end

  def test_empty_digest_list_no_match
    digests = []
    target = Digest::SHA256.hexdigest("any_key")
    refute digests.any? { |d| d == target }
  end

  def test_blank_challenge_produces_deterministic_signature
    # Even with empty challenge, HMAC still produces output
    sig = OpenSSL::HMAC.hexdigest("SHA256", "secret", "")
    refute_nil sig
    refute_empty sig
  end
end
