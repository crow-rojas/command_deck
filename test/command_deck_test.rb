# frozen_string_literal: true

require "test_helper"

class CommandDeckTest < Minitest::Test
  def setup
    # Reset panel_classes before each test
    CommandDeck.instance_variable_set(:@panel_classes, nil)
    CommandDeck::Registry.clear!
  end

  def teardown
    CommandDeck.instance_variable_set(:@panel_classes, nil)
    CommandDeck::Registry.clear!
  end

  def test_that_it_has_a_version_number
    refute_nil ::CommandDeck::VERSION
  end

  def test_panel_classes_returns_array
    assert_kind_of Array, CommandDeck.panel_classes
  end

  def test_panel_classes_memoized
    first_call = CommandDeck.panel_classes
    second_call = CommandDeck.panel_classes

    assert_same first_call, second_call
  end

  def test_register_panel_class_adds_class_to_empty_array
    # Ensure array is empty first to hit the "add" branch
    CommandDeck.instance_variable_set(:@panel_classes, [])
    klass = Class.new
    CommandDeck.register_panel_class(klass)

    assert_includes CommandDeck.panel_classes, klass
    assert_equal 1, CommandDeck.panel_classes.size
  end

  def test_register_panel_class_adds_class
    klass = Class.new
    CommandDeck.register_panel_class(klass)

    assert_includes CommandDeck.panel_classes, klass
  end

  def test_register_panel_class_does_not_duplicate
    klass = Class.new
    CommandDeck.register_panel_class(klass)
    CommandDeck.register_panel_class(klass)

    assert_equal 1, CommandDeck.panel_classes.count(klass)
  end

  def test_register_all_panels_calls_register_on_each_class
    registered = []
    klass1 = Class.new do
      define_singleton_method(:register!) { registered << :klass1 }
    end
    klass2 = Class.new do
      define_singleton_method(:register!) { registered << :klass2 }
    end

    CommandDeck.register_panel_class(klass1)
    CommandDeck.register_panel_class(klass2)
    CommandDeck.register_all_panels!

    assert_equal %i[klass1 klass2], registered
  end

  def test_error_class_exists
    assert_operator CommandDeck::Error, :<, StandardError
  end
end
