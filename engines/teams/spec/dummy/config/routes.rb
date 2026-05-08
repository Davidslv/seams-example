# frozen_string_literal: true

Rails.application.routes.draw do
  mount Teams::Engine, at: "/teams"
end
