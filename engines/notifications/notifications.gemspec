# frozen_string_literal: true

require_relative "lib/notifications/version"

Gem::Specification.new do |spec|
  spec.name        = "notifications"
  spec.version     = Notifications::VERSION
  spec.authors     = ["TODO"]
  spec.email       = ["TODO"]
  spec.summary     = "TODO: short summary of the notifications engine"
  spec.description = "TODO: longer description"
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]

  spec.required_ruby_version = ">= 3.2.0"

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "seams"
end
