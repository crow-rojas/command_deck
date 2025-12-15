# frozen_string_literal: true

require "test_helper"

class ExecutorTest < Minitest::Test
  def setup
    CommandDeck::Registry.clear!
  end

  def teardown
    CommandDeck::Registry.clear!
    CommandDeck.reset_configuration!
  end

  private

  def register_capturing_action(key)
    captured = nil
    CommandDeck::Registry.panel("Test") do
      tab("Tab") { action("Action", key: key) { perform { |_p, ctx| captured = ctx } } }
    end
    -> { captured }
  end

  def register_action_with_params(key, params_schema)
    CommandDeck::Registry.panel("Test") do
      tab("Tab") do
        action("Action", key: key) do
          params_schema.each { |p| param(p[:name], p[:type]) }
          perform { |p, _c| p }
        end
      end
    end
  end

  public

  def test_call_raises_for_unknown_action
    assert_raises(ArgumentError) do
      CommandDeck::Executor.call(key: "unknown.action", params: {})
    end
  end

  def test_call_executes_action_block
    result_holder = nil
    CommandDeck::Registry.panel("Test") do
      tab("Tab") do
        action("Do", key: "test.do") do
          perform do |_p, _c|
            result_holder = :executed
            :success
          end
        end
      end
    end

    result = CommandDeck::Executor.call(key: "test.do", params: {})

    assert_equal :executed, result_holder
    assert_equal :success, result
  end

  def test_call_passes_coerced_params
    register_action_with_params("test.params", [{ name: :count, type: :integer }])

    result = CommandDeck::Executor.call(key: "test.params", params: { "count" => "42" })

    assert_equal 42, result[:count]
  end

  def test_coerce_returns_empty_hash_for_nil_schema
    result = CommandDeck::Executor.coerce(nil, { foo: "bar" })

    assert_empty(result)
  end

  def test_coerce_returns_empty_hash_for_empty_schema
    result = CommandDeck::Executor.coerce([], { foo: "bar" })

    assert_empty(result)
  end

  def test_coerce_with_string_keys
    schema = [{ name: :name, type: :string }]
    result = CommandDeck::Executor.coerce(schema, { "name" => "test" })

    assert_equal "test", result[:name]
  end

  def test_coerce_with_symbol_keys
    schema = [{ name: :name, type: :string }]
    result = CommandDeck::Executor.coerce(schema, { name: "test" })

    assert_equal "test", result[:name]
  end

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

  def test_boolean_true_values
    assert CommandDeck::Executor.boolean_true?(true)
    assert CommandDeck::Executor.boolean_true?("true")
    assert CommandDeck::Executor.boolean_true?("1")
    assert CommandDeck::Executor.boolean_true?("on")
    assert CommandDeck::Executor.boolean_true?("  TRUE  ")
  end

  def test_boolean_false_values
    refute CommandDeck::Executor.boolean_true?(false)
    refute CommandDeck::Executor.boolean_true?(nil)
    refute CommandDeck::Executor.boolean_true?("false")
    refute CommandDeck::Executor.boolean_true?("0")
    refute CommandDeck::Executor.boolean_true?("off")
  end

  def test_integer_or_nil_with_nil
    assert_nil CommandDeck::Executor.integer_or_nil(nil)
  end

  def test_integer_or_nil_with_empty_string
    assert_nil CommandDeck::Executor.integer_or_nil("")
  end

  def test_integer_or_nil_with_value
    assert_equal 123, CommandDeck::Executor.integer_or_nil("123")
    assert_equal 0, CommandDeck::Executor.integer_or_nil("0")
  end

  def test_coerce_string_with_nil
    assert_nil CommandDeck::Executor.coerce_string(nil)
  end

  def test_coerce_string_with_value
    assert_equal "42", CommandDeck::Executor.coerce_string(42)
  end

  def test_symbolize_keys_shallow_with_non_symbol_key
    hash = { 123 => "value" }
    result = CommandDeck::Executor.symbolize_keys_shallow(hash)

    assert_equal({ 123 => "value" }, result)
  end

  def test_call_with_nil_params
    CommandDeck::Registry.panel("Test") do
      tab("Tab") do
        action("Do", key: "test.nil_params") do
          perform { |p, _c| p }
        end
      end
    end

    result = CommandDeck::Executor.call(key: "test.nil_params", params: nil)

    assert_empty(result)
  end
end
