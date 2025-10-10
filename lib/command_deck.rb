# frozen_string_literal: true

require_relative "command_deck/version"
require "command_deck/registry"
require "command_deck/executor"
require "command_deck/base_panel"

# Main module of the Command Deck gem
module CommandDeck
  class Error < StandardError; end

  class << self
    def panel_classes
      @panel_classes ||= []
    end

    def register_panel_class(klass)
      panel_classes << klass unless panel_classes.include?(klass)
    end

    def register_all_panels!
      panel_classes.each(&:register!)
    end
  end
end

require "command_deck/engine" if defined?(Rails)
