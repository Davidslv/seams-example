# frozen_string_literal: true

Rails.application.configure do
  config.cache_classes               = true
  config.eager_load                  = false
  config.public_file_server.enabled  = true
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions   = :rescuable
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr

  # Throwaway keys for the dummy app so models that declare
  # `encrypts` can round-trip in specs. The dummy DB is wiped
  # every run, so deterministic strings are safe here.
  # Hosts use `bin/rails db:encryption:init` + Rails credentials.
  config.active_record.encryption.primary_key            = "dummy_primary_key_for_tests_only"
  config.active_record.encryption.deterministic_key      = "dummy_deterministic_key_for_tests_only"
  config.active_record.encryption.key_derivation_salt    = "dummy_key_derivation_salt_for_tests_only"
  config.active_record.encryption.support_unencrypted_data = true

  # Mailer specs render views that call URL helpers (e.g.
  # `edit_password_reset_url`). Without a host they raise
  # "Missing host to link to!". `test.host` is the Rails
  # test convention.
  config.action_mailer.delivery_method     = :test
  config.action_mailer.default_url_options = { host: "test.host" }
end
