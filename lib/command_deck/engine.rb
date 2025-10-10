# frozen_string_literal: true

require "rails/engine"
require_relative "middleware"

module CommandDeck
  # Rails engine for Command Deck
  class Engine < ::Rails::Engine
    isolate_namespace CommandDeck

    initializer "command_deck.add_autoload_paths", before: :set_autoload_paths do |app|
      panels_path = Rails.root.join("app/command_deck")
      app.config.autoload_paths << panels_path.to_s if panels_path.exist?
    end

    initializer "command_deck.mount_point" do
      mp = "/command_deck"
      if defined?(Rails) && Rails.application.config.respond_to?(:relative_url_root)
        root = Rails.application.config.relative_url_root
        mp = File.join(root, mp) if root.present?
      end
      CommandDeck::Middleware.mount_point = mp
    end

    config.to_prepare do
      next unless Rails.env.development?

      CommandDeck::Registry.clear!

      if defined?(Panels)
        Panels.constants.each do |const_name|
          Panels.const_get(const_name)
        rescue NameError => e
          Rails.logger.warn "[CommandDeck] Could not load panel: #{e.message}"
        end
      end

      CommandDeck.register_all_panels!
    end
  end
end
