# frozen_string_literal: true

require "test_helper"

class RegistryTest < Minitest::Test
  def setup
    CommandDeck::Registry.clear!
  end

  def teardown
    CommandDeck::Registry.clear!
  end

  def test_registers_panel_and_finds_action # rubocop:disable Metrics/MethodLength
    CommandDeck.panel "My Panel" do
      tab "Main" do
        action "Do", key: "my.do" do
          param :name, :string
          perform { |p, _| p[:name] }
        end
      end
    end

    action = CommandDeck::Registry.find_action("my.do")
    refute_nil action
    assert_equal "Do", action.title
    assert_equal :string, action.params.first[:type]
  end

  def test_slugify_key
    CommandDeck.panel "My Fancy Panel" do
      tab "T" do
        action "A", key: "a.k"
      end
    end
    panel = CommandDeck::Registry.panels.first
    assert_equal "my-fancy-panel", panel.key
  end
end
