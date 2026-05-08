# frozen_string_literal: true

class User < ApplicationRecord
  include Notifications::Notifiable
end
