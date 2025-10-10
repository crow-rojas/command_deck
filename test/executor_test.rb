# frozen_string_literal: true

require "test_helper"

class ExecutorTest < Minitest::Test
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
end
