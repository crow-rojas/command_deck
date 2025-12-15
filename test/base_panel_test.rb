# frozen_string_literal: true

require "test_helper"

class BasePanelTest < Minitest::Test
  def setup
    CommandDeck.instance_variable_set(:@panel_classes, nil)
    CommandDeck::Registry.clear!
  end

  def teardown
    CommandDeck.instance_variable_set(:@panel_classes, nil)
    CommandDeck::Registry.clear!
  end

  def test_panel_stores_definition
    klass = Class.new(CommandDeck::BasePanel)
    klass.panel("Test Panel", owner: "me") {}

    definition = klass.instance_variable_get(:@panel_definition)

    assert_equal "Test Panel", definition[:title]
    assert_equal({ owner: "me" }, definition[:opts])
    assert_kind_of Proc, definition[:block]
  end

  def test_register_does_nothing_without_panel_definition
    klass = Class.new(CommandDeck::BasePanel)
    # Don't call panel method

    klass.register!

    assert_empty CommandDeck::Registry.panels
  end

  def test_register_creates_panel_in_registry
    klass = Class.new(CommandDeck::BasePanel) do
      panel "My Panel" do
        tab "Tab1" do
          action "Act", key: "my.act" do
            perform { |_p, _c| :done }
          end
        end
      end
    end

    klass.register!

    assert_equal 1, CommandDeck::Registry.panels.size
    assert_equal "My Panel", CommandDeck::Registry.panels.first.title
  end

  def test_inherited_registers_subclass
    # When we create a subclass, it should be registered automatically
    subclass = Class.new(CommandDeck::BasePanel)

    assert_includes CommandDeck.panel_classes, subclass
  end
end
