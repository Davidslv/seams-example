# frozen_string_literal: true

require_relative "spec_helper"
ENV["RAILS_ENV"] ||= "test"

# Ensure the per-engine Postgres test database exists before
# the dummy app boots and tries to connect to it. We connect
# to the maintenance "postgres" database first, CREATE DATABASE
# if missing, then let the dummy app pick up its own config.
require "active_record"
require "yaml"
require "erb"
dummy_db_yml = File.expand_path("dummy/config/database.yml", __dir__)
db_config    = YAML.safe_load(ERB.new(File.read(dummy_db_yml)).result, aliases: true)["test"]
target_db    = db_config["database"]
admin_config = db_config.merge("database" => "postgres")
ActiveRecord::Base.establish_connection(admin_config)
unless ActiveRecord::Base.connection.execute(
  "SELECT 1 FROM pg_database WHERE datname = '#{target_db}'"
).any?
  ActiveRecord::Base.connection.execute(%(CREATE DATABASE "#{target_db}"))
end
ActiveRecord::Base.remove_connection

require File.expand_path("dummy/config/environment", __dir__)
abort("Rails is in production mode!") if Rails.env.production?

require "rspec/rails"

# WebMock is optional — engines that stub outbound HTTP
# (billing's stub_stripe helpers, auth's OAuth adapter
# specs) bring in `webmock` via the host Gemfile. If
# available, require it so specs can call WebMock.stub_request
# without each one re-requiring it. We disable real HTTP
# connections to make missing stubs explicit instead of
# accidentally hitting the network.
begin
  require "webmock/rspec"
  WebMock.disable_net_connect!(allow_localhost: true)
rescue LoadError
  # webmock isn't bundled — engines that don't stub HTTP
  # don't need it.
end

# FactoryBot is optional — engines that ship factories add
# `factory_bot_rails` to the host Gemfile. If it's loaded, wire
# the syntax methods + auto-discover the engine's
# spec/factories/*.rb (default search paths look in the host's
# spec/factories which doesn't exist when running engine specs
# from the host root).
if defined?(FactoryBot)
  require "factory_bot_rails"
  engine_factories = File.expand_path("factories", __dir__)
  FactoryBot.definition_file_paths = [engine_factories]
  FactoryBot.find_definitions if FactoryBot.factories.none?
end

ActiveRecord::Schema.verbose = false
# Drop and reload the schema for a clean slate every run.
ActiveRecord::Base.connection.tables.each do |t|
  ActiveRecord::Base.connection.drop_table(t, force: :cascade)
end
load File.expand_path("dummy/db/schema.rb", __dir__)

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  if defined?(FactoryBot)
    config.include FactoryBot::Syntax::Methods
  end
end
