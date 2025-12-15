# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    CommandDeck.reset_configuration!
  end

  def teardown
    CommandDeck.reset_configuration!
  end

  def test_default_context_provider_returns_empty_hash
    config = CommandDeck::Configuration.new
    result = config.build_context({})

    assert_empty(result)
  end

  def test_build_context_calls_provider_with_request
    config = CommandDeck::Configuration.new
    config.context_provider = ->(req) { { path: req[:path] } }

    result = config.build_context({ path: "/test" })

    assert_equal({ path: "/test" }, result)
  end

  def test_build_context_returns_empty_when_provider_not_callable
    config = CommandDeck::Configuration.new
    config.context_provider = "not callable"

    result = config.build_context({})

    assert_empty(result)
  end

  def test_build_context_returns_empty_when_provider_returns_nil
    config = CommandDeck::Configuration.new
    config.context_provider = ->(_req) {}

    result = config.build_context({})

    assert_empty(result)
  end

  def test_build_context_handles_exception_gracefully_without_rails
    # Test exception handling when Rails is NOT defined
    rails_was_defined = defined?(Rails)
    original_rails = Rails if rails_was_defined
    Object.send(:remove_const, :Rails) if rails_was_defined

    config = CommandDeck::Configuration.new
    config.context_provider = ->(_req) { raise StandardError, "boom" }

    result = config.build_context({})

    assert_empty(result)
  ensure
    Object.const_set(:Rails, original_rails) if rails_was_defined && original_rails
  end

  def test_build_context_handles_exception_gracefully_with_rails
    # Test exception handling when Rails IS defined - covers the Rails.logger.warn branch
    warned_messages = []
    mock_logger = Class.new do
      define_method(:warn) { |msg| warned_messages << msg }
    end.new

    rails_was_defined = defined?(Rails)
    original_rails = Rails if rails_was_defined

    Object.send(:remove_const, :Rails) if rails_was_defined
    Object.const_set(:Rails, Module.new do
      define_singleton_method(:logger) { mock_logger }
    end)

    config = CommandDeck::Configuration.new
    config.context_provider = ->(_req) { raise StandardError, "boom" }

    result = config.build_context({})

    assert_empty(result)
    assert_equal 1, warned_messages.size
    assert_includes warned_messages.first, "Context provider error: boom"
  ensure
    Object.send(:remove_const, :Rails) if defined?(Rails)
    Object.const_set(:Rails, original_rails) if rails_was_defined && original_rails
  end

  def test_configuration_singleton
    config1 = CommandDeck.configuration
    config2 = CommandDeck.configuration

    assert_same config1, config2
  end

  def test_configure_yields_configuration
    yielded = nil
    CommandDeck.configure { |c| yielded = c }

    assert_same CommandDeck.configuration, yielded
  end

  def test_reset_configuration_creates_new_instance
    original = CommandDeck.configuration
    CommandDeck.reset_configuration!

    refute_same original, CommandDeck.configuration
  end
end
