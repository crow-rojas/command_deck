# frozen_string_literal: true

require "rails/railtie"

module CommandDeck
  # Rails engine for Command Deck
  class Railtie < ::Rails::Railtie
    initializer "command_deck.load_panels", after: :load_config_initializers do
      path = Rails.root.join("app/command_deck")
      Dir[path.join("**/*.rb")].each { |f| load f } if Dir.exist?(path)
    end
  end
end
