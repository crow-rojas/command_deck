# frozen_string_literal: true

require "rails/engine"
require_relative "middleware"

module CommandDeck
  # Rails engine for Command Deck
  class Engine < ::Rails::Engine
    isolate_namespace CommandDeck

    initializer "command_deck.mount_point" do
      # Default mount point. If the host app has a relative_url_root, respect it.
      mp = "/command_deck"
      if defined?(Rails) && Rails.application.config.respond_to?(:relative_url_root)
        root = Rails.application.config.relative_url_root
        mp = File.join(root, mp) if root.present?
      end
      CommandDeck::Middleware.mount_point = mp
    end

    initializer "command_deck.middleware" do |app|
      # Dev-only injection. Safe no-op in other environments.
      if defined?(Rails) && Rails.env.development?
        app.middleware.insert_after ActionDispatch::DebugExceptions, CommandDeck::Middleware
      end
    end
  end
end
