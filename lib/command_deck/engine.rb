# frozen_string_literal: true

require "rails/engine"
require_relative "middleware"

module CommandDeck
  # Rails engine for Command Deck
  class Engine < ::Rails::Engine
    isolate_namespace CommandDeck

    initializer "command_deck.add_autoload_paths", before: :set_autoload_paths do |app|
      discover_panel_paths.each do |path|
        app.config.autoload_paths << path.to_s unless app.config.autoload_paths.include?(path.to_s)
      end
    end

    initializer "command_deck.mount_point" do
      mp = "/command_deck"
      if defined?(Rails) && Rails.application.config.respond_to?(:relative_url_root)
        root = Rails.application.config.relative_url_root
        mp = File.join(root, mp) if root.present?
      end
      CommandDeck::Middleware.mount_point = mp
    end

    initializer "command_deck.middleware", after: :load_config_initializers do |app|
      next unless Rails.env.development?
      next unless ENV.fetch("COMMAND_DECK_ENABLED", "false") == "true"

      unless app.config.middleware.include?(CommandDeck::Middleware)
        app.config.middleware.insert_after(
          ActionDispatch::DebugExceptions,
          CommandDeck::Middleware
        )
      end
    end

    config.to_prepare do
      next unless Rails.env.development?

      CommandDeck::Registry.clear!
      CommandDeck.register_all_panels!
    end

    class << self
      private

      def discover_panel_paths
        [discover_app_panels, discover_pack_panels].flatten.compact.uniq
      end

      def discover_app_panels
        path = Rails.root.join("app/command_deck")
        path if path.exist?
      end

      def discover_pack_panels
        packs_path = Rails.root.join("packs")
        return [] unless packs_path.exist?

        Dir.glob(packs_path.join("**/command_deck")).select { |dir| Pathname.new(dir).directory? }
      end
    end
  end
end
