# frozen_string_literal: true

Rails.application.routes.draw do
  mount Accounts::Engine, at: "/accounts"
end
