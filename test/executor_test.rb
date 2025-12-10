# frozen_string_literal: true

require "test_helper"

class ExecutorTest < Minitest::Test
  private

  def register_capturing_action(key)
    captured = nil
    CommandDeck::Registry.panel("Test") do
      tab("Tab") { action("Action", key: key) { perform { |_p, ctx| captured = ctx } } }
    end
    -> { captured }
  end

  public

  def test_boolean_coercion
    schema = [
      { name: :flag, type: :boolean }
    ]
    out = CommandDeck::Executor.coerce(schema, { "flag" => "true" })

    assert out[:flag]

    out = CommandDeck::Executor.coerce(schema, { flag: "0" })

    refute out[:flag]
  end

  def test_integer_coercion
    schema = [
      { name: :count, type: :integer }
    ]
    out = CommandDeck::Executor.coerce(schema, { count: "42" })

    assert_equal 42, out[:count]

    out = CommandDeck::Executor.coerce(schema, { count: "" })

    assert_nil out[:count]
  end

  def test_selector_preserves_value
    schema = [
      { name: :sel, type: :selector }
    ]

    # value only
    out = CommandDeck::Executor.coerce(schema, { sel: 123 })

    assert_equal 123, out[:sel]

    # object with label+value should symbolize keys
    out = CommandDeck::Executor.coerce(schema, { sel: { "label" => "Foo", "value" => 7 } })

    assert_equal({ label: "Foo", value: 7 }, out[:sel])
  end

  def test_context_provider_is_called_with_request
    CommandDeck::Registry.clear!
    get_ctx = register_capturing_action("test.ctx")
    fake_user = { id: 42, name: "Test User" }
    CommandDeck.configure { |c| c.context_provider = ->(req) { { user: fake_user, path: req[:path] } } }

    CommandDeck::Executor.call(key: "test.ctx", params: {}, request: { path: "/test" })

    assert_equal fake_user, get_ctx.call[:user]
    assert_equal "/test", get_ctx.call[:path]
  ensure
    CommandDeck.reset_configuration!
    CommandDeck::Registry.clear!
  end

  def test_context_is_empty_hash_without_request
    CommandDeck::Registry.clear!
    get_ctx = register_capturing_action("test.no_ctx")

    CommandDeck::Executor.call(key: "test.no_ctx", params: {})

    assert_empty(get_ctx.call)
  ensure
    CommandDeck::Registry.clear!
  end
end
