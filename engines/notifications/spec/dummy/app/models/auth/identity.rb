# frozen_string_literal: true

module Auth
  class Identity < ApplicationRecord
    self.table_name = "auth_identities"
    include Notifications::Notifiable
  end
end
