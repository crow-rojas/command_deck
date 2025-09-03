# frozen_string_literal: true

CommandDeck::Engine.routes.draw do
  resources :actions, only: [:create]
  # You can add more endpoints here later (e.g., CRUD views)
end
