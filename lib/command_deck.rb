# frozen_string_literal: true

require_relative "command_deck/version"
require "command_deck/registry"
require "command_deck/executor"
require "command_deck/railtie"

module CommandDeck
  class Error < StandardError; end
end

require "command_deck/engine"
