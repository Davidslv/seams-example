# frozen_string_literal: true

# Minimal host User for the engine's spec/dummy app.
class User < ApplicationRecord
  include Core::Auditable
end
