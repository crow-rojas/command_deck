# frozen_string_literal: true

require_relative "command_deck/version"

module CommandDeck
  class Error < StandardError; end
end

# Load the Rails engine so middleware and routes are registered when the gem is required.
require "command_deck/engine"
