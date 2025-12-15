# frozen_string_literal: true

require "test_helper"

class RegistryTest < Minitest::Test
  def setup
    CommandDeck::Registry.clear!
  end

  def teardown
    CommandDeck::Registry.clear!
  end

  def test_panels_returns_array
    assert_kind_of Array, CommandDeck::Registry.panels
  end

  def test_panels_memoized
    first = CommandDeck::Registry.panels
    second = CommandDeck::Registry.panels

    assert_same first, second
  end

  def test_clear_resets_panels
    CommandDeck::Registry.panel("Test") { tab("T") { action("A", key: "t.a") } }

    refute_empty CommandDeck::Registry.panels

    CommandDeck::Registry.clear!

    assert_empty CommandDeck::Registry.panels
  end

  def test_registers_panel_and_finds_action
    panel_class = Class.new(CommandDeck::BasePanel) do
      panel "My Panel" do
        tab "Main" do
          action "Do", key: "my.do" do
            param :name, :string
            perform { |p, _| p[:name] }
          end
        end
      end
    end

    panel_class.register!

    action = CommandDeck::Registry.find_action("my.do")

    refute_nil action
    assert_equal "Do", action.title
    assert_equal :string, action.params.first[:type]
  end

  def test_slugify_key
    panel_class = Class.new(CommandDeck::BasePanel) do
      panel "My Fancy Panel" do
        tab "T" do
          action "A", key: "a.k"
        end
      end
    end

    panel_class.register!

    panel = CommandDeck::Registry.panels.first

    assert_equal "my-fancy-panel", panel.key
  end

  def test_find_action_returns_nil_for_unknown_key
    CommandDeck::Registry.panel("Test") do
      tab("Tab") { action("Act", key: "test.act") }
    end

    result = CommandDeck::Registry.find_action("nonexistent.key")

    assert_nil result
  end

  def test_panel_without_block
    CommandDeck::Registry.panel("Empty Panel")

    panel = CommandDeck::Registry.panels.first

    assert_equal "Empty Panel", panel.title
    assert_empty panel.tabs
  end

  def test_panel_with_owner_and_group
    CommandDeck::Registry.panel("Test", owner: "team-a", group: "admin") do
      tab("Tab") { action("Act", key: "t.a") }
    end

    panel = CommandDeck::Registry.panels.first

    assert_equal "team-a", panel.owner
    assert_equal "admin", panel.group
  end

  def test_panel_with_custom_key
    CommandDeck::Registry.panel("Test", key: "custom-key") do
      tab("Tab") { action("Act", key: "t.a") }
    end

    panel = CommandDeck::Registry.panels.first

    assert_equal "custom-key", panel.key
  end

  def test_tab_without_block
    CommandDeck::Registry.panel("Test") do
      tab("Empty Tab")
    end

    tab = CommandDeck::Registry.panels.first.tabs.first

    assert_equal "Empty Tab", tab.title
    assert_empty tab.actions
  end

  def test_action_without_block
    CommandDeck::Registry.panel("Test") do
      tab("Tab") { action("No Block", key: "test.no_block") }
    end

    action = CommandDeck::Registry.find_action("test.no_block")

    assert_equal "No Block", action.title
    assert_empty action.params
    assert_nil action.block
  end

  def test_action_with_multiple_params
    CommandDeck::Registry.panel("Test") do
      tab("Tab") do
        action("Multi", key: "test.multi") do
          param :name, :string, required: true
          param :count, :integer
          param :active, :boolean
        end
      end
    end

    action = CommandDeck::Registry.find_action("test.multi")

    assert_equal 3, action.params.size
    assert_equal :name, action.params[0][:name]
    assert_equal :string, action.params[0][:type]
    assert action.params[0][:required]
    assert_equal :count, action.params[1][:name]
    assert_equal :integer, action.params[1][:type]
  end

  def test_find_action_searches_all_panels_and_tabs
    CommandDeck::Registry.panel("Panel1") do
      tab("Tab1") { action("Act1", key: "p1.t1.a1") }
      tab("Tab2") { action("Act2", key: "p1.t2.a2") }
    end
    CommandDeck::Registry.panel("Panel2") do
      tab("Tab1") { action("Act3", key: "p2.t1.a3") }
    end

    assert_equal "Act1", CommandDeck::Registry.find_action("p1.t1.a1").title
    assert_equal "Act2", CommandDeck::Registry.find_action("p1.t2.a2").title
    assert_equal "Act3", CommandDeck::Registry.find_action("p2.t1.a3").title
  end

  def test_slugify_handles_special_characters
    CommandDeck::Registry.panel("Test!@#Panel  With---Spaces") do
      tab("T") { action("A", key: "t.a") }
    end

    panel = CommandDeck::Registry.panels.first

    assert_equal "test-panel-with-spaces", panel.key
  end
end
