# frozen_string_literal: true

require_relative "command_deck/version"
require "command_deck/registry"
require "command_deck/executor"

module CommandDeck
  class Error < StandardError; end
end

if defined?(Rails)
  require "command_deck/railtie"
  require "command_deck/engine"
end
