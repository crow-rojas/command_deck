# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

begin
  require "simplecov"
  SimpleCov.enable_coverage :branch
  SimpleCov.start do
    add_filter "/test/"
  end
rescue LoadError
  warn "SimpleCov not available; coverage disabled"
end

require "rack"
require "command_deck"

require "minitest/autorun"
