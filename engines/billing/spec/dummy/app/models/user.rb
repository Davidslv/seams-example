# frozen_string_literal: true

class User < ApplicationRecord
  include Billing::Billable
end
