# frozen_string_literal: true

# Auth::Identity encrypts :email (and Auth::OAuth::Provider encrypts
# :provider_uid + :access_token) via Rails 7+ ActiveRecord::Encryption.
# Real production hosts run `bin/rails db:encryption:init` once and
# store the keys in Rails credentials. The seams-example demo ships
# throwaway dev/test keys so a fresh `bin/rails db:setup` boots without
# manual key-generation.
#
# Replace these with credential-stored values in any host that handles
# real PII.
Rails.application.configure do
  config.active_record.encryption.primary_key            = "seams_example_demo_primary_key_throwaway"
  config.active_record.encryption.deterministic_key      = "seams_example_demo_deterministic_key_throwaway"
  config.active_record.encryption.key_derivation_salt    = "seams_example_demo_key_derivation_salt_throwaway"
  config.active_record.encryption.support_unencrypted_data = true
end
