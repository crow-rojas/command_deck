# frozen_string_literal: true

CommandDeck::Engine.routes.draw do
  get   "/assets/js/*path",  to: "assets#js"
  get   "/assets/css/*path", to: "assets#css"

  get   "/panels", to: "panels#index"
  resources :actions, only: [:create]
end
