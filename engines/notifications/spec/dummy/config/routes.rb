# frozen_string_literal: true

Rails.application.routes.draw do
  mount Notifications::Engine, at: "/notifications"
end
