# frozen_string_literal: true

class User < ApplicationRecord
  self.table_name = "auth_users"
  include Auth::Authenticatable
end
