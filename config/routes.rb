# frozen_string_literal: true

CommandDeck::Engine.routes.draw do
  get   "/assets/js.js", to: "assets#js"
  get   "/assets/css.css", to: "assets#css"

  get   "/panels", to: "panels#index"
  resources :actions, only: [:create]
end
