# frozen_string_literal: true

Rails.application.routes.draw do
  root "showcase#show"
  post "/", to: "showcase#create", as: :posts
  post "/chips", to: "showcase#chips", as: :chips
  resources :articles, only: %i[new create edit update]
end
