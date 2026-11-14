# frozen_string_literal: true

Rails.application.routes.draw do
  root "showcase#show"
  post "/", to: "showcase#create", as: :posts
end
