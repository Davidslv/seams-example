# frozen_string_literal: true
module Auth
  class Identity < ApplicationRecord
    self.table_name = "auth_identities"
    has_secure_password
  end
end
